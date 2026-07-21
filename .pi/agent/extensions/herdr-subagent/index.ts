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
import { Herdr } from "./herdr.ts";

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
  status: string,
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
  agent: Type.String({ description: "Generated name returned by subagent" }),
  prompt: Type.String({ description: "Follow-up or steering prompt to submit" }),
});

const SubagentWaitParams = Type.Object({
  agent: Type.String({ description: "Generated name returned by subagent" }),
});

export default function (pi: ExtensionAPI): void {
  if (process.env.HERDR_ENV !== "1") return;

  const herdr = new Herdr(pi);

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description: [
      "Start an independent Pi subagent with its own context window in a new background Herdr tab.",
      "Returns the generated agent name after submitting the initial prompt and observing the agent working, without waiting for completion.",
      "Use the name with subagent_send for follow-ups.",
      "Only call subagent_wait when you need the response to continue; otherwise leave the subagent running in the background.",
    ].join(" "),
    parameters: SubagentParams,
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const workspaceId = process.env.HERDR_WORKSPACE_ID;
      if (!workspaceId || !process.env.HERDR_PANE_ID) {
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
      const tab = await herdr.createTab({ cwd: ctx.cwd, label: agent, workspaceId }, signal);
      const paneId = tab.result.root_pane.pane_id;
      await herdr.waitForShell(paneId, signal);
      await herdr.startAgent({ name: agent, paneId, piArgs }, signal);
      const prompted = await herdr.promptAgent(agent, params.prompt, signal);
      return {
        content: [{ type: "text", text: agent }],
        details: {
          agent,
          paneId,
          tabId: tab.result.tab.tab_id,
          status: prompted.result.agent.agent_status,
        },
      };
    },
  });

  pi.registerTool({
    name: "subagent_send",
    label: "Send to subagent",
    description: [
      "Submit a follow-up or steering prompt to a running subagent.",
      "Returns after submitting the prompt and observing the agent working, without waiting for completion.",
      "Only call subagent_wait afterward when you need the response to continue; otherwise do not wait.",
    ].join(" "),
    parameters: SubagentSendParams,
    async execute(_toolCallId, params, signal) {
      const prompted = await herdr.promptAgent(params.agent, params.prompt, signal);
      return {
        content: [{ type: "text", text: `Delivered to ${params.agent}.` }],
        details: { agent: params.agent, paneId: prompted.result.agent.pane_id },
      };
    },
  });

  pi.registerTool({
    name: "subagent_wait",
    label: "Wait for subagent",
    description: [
      "Wait indefinitely for a subagent to become idle, done, or blocked, then return its status and latest assistant response.",
      "Use this only when you need the response or status to continue your main thread.",
    ].join(" "),
    parameters: SubagentWaitParams,
    async execute(_toolCallId, params, signal) {
      const resolved = await herdr.waitForAgent(params.agent, signal);
      const status = resolved.result.agent.agent_status;
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
