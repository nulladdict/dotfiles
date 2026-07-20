import { randomUUID } from "node:crypto";
import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  formatSize,
  SessionManager,
  truncateTail,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import { Herdr, type HerdrAgentStatus, type SettledStatus } from "./herdr.ts";

async function waitForSettledStatus(
  herdr: Herdr,
  agent: string,
  signal: AbortSignal | undefined,
): Promise<SettledStatus> {
  const stopOtherWait = new AbortController();
  const waitSignal = signal
    ? AbortSignal.any([signal, stopOtherWait.signal])
    : stopOtherWait.signal;
  try {
    const response = await Promise.race([
      herdr.waitForAgentStatus(agent, "idle", waitSignal),
      herdr.waitForAgentStatus(agent, "blocked", waitSignal),
    ]);
    const status =
      "result" in response ? response.result.agent.agent_status : response.data.agent_status;
    return status === "blocked" ? "blocked" : "idle";
  } finally {
    stopOtherWait.abort();
  }
}

function normalizeSettledStatus(status: HerdrAgentStatus): SettledStatus | undefined {
  if (status === "blocked") return "blocked";
  if (status === "idle" || status === "done") return "idle";
  return undefined;
}

function latestAssistantText(session: SessionManager): string {
  for (const entry of session.buildContextEntries().toReversed()) {
    if (entry.type !== "message") continue;
    const message = entry.message;
    if (message.role !== "assistant") continue;

    const text = message.content
      .filter((block) => block.type === "text")
      .map((block) => block.text)
      .join("");
    if (text) return text;
    return message.errorMessage || message.stopReason || "(assistant returned no text)";
  }

  return "(no assistant message available)";
}

async function formatWaitOutput(
  status: SettledStatus,
  assistantText: string,
  signal?: AbortSignal,
): Promise<{ text: string; fullOutputPath?: string }> {
  const full = `Status: ${status}\n\n${assistantText}`;
  const initial = truncateTail(full, {
    maxLines: DEFAULT_MAX_LINES,
    maxBytes: DEFAULT_MAX_BYTES,
  });
  if (!initial.truncated) return { text: full };

  const tempDir = await mkdtemp(join(tmpdir(), "pi-subagent-wait-"));
  const fullOutputPath = join(tempDir, "output.log");
  await writeFile(fullOutputPath, full, { encoding: "utf8", signal });

  const truncated = truncateTail(assistantText, {
    maxLines: DEFAULT_MAX_LINES - 3,
    maxBytes: DEFAULT_MAX_BYTES - 512,
  });
  const notice = `[Output truncated: showing the newest ${truncated.outputLines} of ${truncated.totalLines} lines (${formatSize(truncated.outputBytes)} of ${formatSize(truncated.totalBytes)}). Full output saved to: ${fullOutputPath}]`;
  return {
    text: `Status: ${status}\n${notice}\n\n${truncated.content}`,
    fullOutputPath,
  };
}

const SubagentParams = Type.Object({
  prompt: Type.String({
    description:
      "Task prompt for the subagent. Must be self-contained: include all needed context, file paths, and what to report back if any.",
  }),
});

const SubagentSendParams = Type.Object({
  agent: Type.String({ description: "Subagent's name" }),
  prompt: Type.String({ description: "Follow-up or steering message to deliver" }),
});

const SubagentWaitParams = Type.Object({
  agent: Type.String({ description: "Subagent's name" }),
});

export default function (pi: ExtensionAPI): void {
  if (process.env.HERDR_ENV !== "1") return;

  const herdr = new Herdr(pi);

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Start a background subagent: a fully autonomous, headless pi thread with its own context window which runs in a separate persistent Herdr pane.",
      "This returns immediately with the subagent's name, which can be used to send follow-up messages or wait for its output if needed.",
    ].join(" "),
    parameters: SubagentParams,
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const workspaceId = process.env.HERDR_WORKSPACE_ID;
      const tabId = process.env.HERDR_TAB_ID;
      if (!workspaceId || !tabId || !process.env.HERDR_PANE_ID) {
        throw new Error("Herdr parent pane metadata is unavailable");
      }
      if (!ctx.model) {
        throw new Error("No active model is available");
      }

      const agent = `pi-subagent-${randomUUID().slice(0, 8)}`;
      const activeTools = pi
        .getActiveTools()
        .filter(
          (tool) => tool !== "subagent" && tool !== "subagent_wait" && tool !== "subagent_send",
        );
      const piArgs = [
        "--model",
        `${ctx.model.provider}/${ctx.model.id}`,
        "--thinking",
        pi.getThinkingLevel(),
        ctx.isProjectTrusted() ? "--approve" : "--no-approve",
      ];
      if (activeTools.length > 0) piArgs.push("--tools", activeTools.join(","));
      else piArgs.push("--no-tools");
      piArgs.push(params.prompt);

      const response = await herdr.startAgent(
        { name: agent, cwd: ctx.cwd, workspaceId, tabId, piArgs },
        signal,
      );
      const paneId = response.result.agent.pane_id;
      const move = await herdr.movePaneToNewTab(paneId, workspaceId, agent, signal);
      return {
        content: [{ type: "text", text: agent }],
        details: {
          agent,
          paneId,
          tabId: move.result.move_result.created_tab.tab_id,
          status: response.result.agent.agent_status,
        },
      };
    },
  });

  pi.registerTool({
    name: "subagent_send",
    label: "Send to subagent",
    description: [
      "Send a follow-up or steering prompt to a subagent.",
      "Use subagent_wait afterward if you need to get its latest response to continue your main thread.",
    ].join(" "),
    parameters: SubagentSendParams,
    async execute(_toolCallId, params, signal) {
      const resolved = await herdr.getAgent(params.agent, signal);
      await herdr.runInPane(resolved.result.agent.pane_id, params.prompt, signal);
      return {
        content: [{ type: "text", text: `Delivered to ${params.agent}.` }],
        details: { agent: params.agent, paneId: resolved.result.agent.pane_id },
      };
    },
  });

  pi.registerTool({
    name: "subagent_wait",
    label: "Wait for subagent",
    description: [
      "Wait for a subagent to become idle or blocked, then read its latest assistant response.",
      "Use this if you need the subagent's output to continue your main thread.",
      "Do not wait for a subagent that is still running if you don't need its output, as it will block your main thread until the subagent finishes.",
    ].join(" "),
    parameters: SubagentWaitParams,
    async execute(_toolCallId, params, signal) {
      const initial = await herdr.getAgent(params.agent, signal);
      const initialStatus = normalizeSettledStatus(initial.result.agent.agent_status);
      const status = initialStatus ?? (await waitForSettledStatus(herdr, params.agent, signal));

      const resolved = await herdr.getAgent(params.agent, signal);
      const session = resolved.result.agent.agent_session;
      if (!session || session.kind !== "path" || !session.value) {
        throw new Error(`Agent ${params.agent} has no session path`);
      }
      const assistantText = latestAssistantText(SessionManager.open(session.value));
      const output = await formatWaitOutput(status, assistantText, signal);
      return {
        content: [{ type: "text", text: output.text }],
        details: {
          agent: params.agent,
          paneId: resolved.result.agent.pane_id,
          status,
          fullOutputPath: output.fullOutputPath,
        },
      };
    },
  });
}
