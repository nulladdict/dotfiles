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

const SpawnAgentParams = Type.Object({
  task_name: Type.String({
    description:
      "Short, unique task name containing only lowercase letters, digits, and underscores. Used as both the agent name and Herdr tab name.",
    pattern: "^[a-z0-9_]+$",
  }),
  message: Type.String({
    description:
      "Self-contained instructions for a concrete, bounded subtask. Include all relevant context, file paths, constraints, and expected output.",
  }),
});

const FollowupTaskParams = Type.Object({
  target: Type.String({ description: "Task name or live pane ID returned by spawn_agent" }),
  message: Type.String({ description: "Additional instructions or steering task for the agent" }),
});

const WaitAgentParams = Type.Object({
  target: Type.String({ description: "Task name or live pane ID returned by spawn_agent" }),
});

export default function (pi: ExtensionAPI): void {
  if (process.env.HERDR_ENV !== "1") return;

  const herdr = new Herdr(pi);

  pi.registerTool({
    name: "spawn_agent",
    label: "spawn_agent",
    description: [
      "Spawn a named background Pi agent to work on a concrete, bounded subtask in a new Herdr tab.",
      "Choose a short, unique task_name containing only lowercase letters, digits, and underscores; it becomes both the agent name and tab name.",
      "The agent receives no parent conversation history, so the message must be self-contained and include all relevant context, file paths, constraints, and expected output.",
      "It inherits the parent's model, reasoning level, working directory, project trust, and active non-collaboration tools; agents cannot spawn nested agents.",
      "Returns the task name and live Herdr pane ID after the agent starts; either can be used as target in followup_task and wait_agent.",
      "Use followup_task for additional instructions and wait_agent only when the result is needed.",
    ].join(" "),
    parameters: SpawnAgentParams,
    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      const workspaceId = process.env.HERDR_WORKSPACE_ID;
      if (!workspaceId || !process.env.HERDR_PANE_ID) {
        throw new Error("Herdr parent pane metadata is unavailable");
      }
      if (!ctx.model) {
        throw new Error("No active model is available");
      }

      const agent = params.task_name;
      const activeTools = pi
        .getActiveTools()
        .filter(
          (tool) => tool !== "spawn_agent" && tool !== "followup_task" && tool !== "wait_agent",
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
      const prompted = await herdr.promptAgent(agent, params.message, signal);
      const status = prompted.result.agent.agent_status;
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ task_name: agent, pane_id: paneId, status }),
          },
        ],
        details: {
          task_name: agent,
          pane_id: paneId,
          tab_id: tab.result.tab.tab_id,
          status,
        },
      };
    },
  });

  pi.registerTool({
    name: "followup_task",
    label: "followup_task",
    description: [
      "Send additional instructions or a steering task to an existing agent identified by a task name or live pane ID returned from spawn_agent.",
      "Returns after the task is delivered and the agent is observed working; it does not wait for completion.",
      "Use wait_agent afterward only when the result is needed immediately.",
    ].join(" "),
    parameters: FollowupTaskParams,
    async execute(_toolCallId, params, signal) {
      const prompted = await herdr.promptAgent(params.target, params.message, signal);
      const paneId = prompted.result.agent.pane_id;
      return {
        content: [{ type: "text", text: `Delivered follow-up task to ${params.target}.` }],
        details: { target: params.target, pane_id: paneId },
      };
    },
  });

  pi.registerTool({
    name: "wait_agent",
    label: "wait_agent",
    description: [
      "Wait indefinitely for a specific agent, identified by a task name or live pane ID returned from spawn_agent, to become idle, done, or blocked.",
      "Returns the agent's resulting status and latest assistant response.",
      "Call only when progress depends on that response; otherwise leave the agent running in the background.",
    ].join(" "),
    parameters: WaitAgentParams,
    async execute(_toolCallId, params, signal) {
      const resolved = await herdr.waitForAgent(params.target, signal);
      const status = resolved.result.agent.agent_status;
      const session = resolved.result.agent.agent_session;
      if (!session || session.kind !== "path" || !session.value) {
        throw new Error(`Agent ${params.target} has no session path`);
      }
      const assistantText = latestAssistantText(SessionManager.open(session.value));
      const output = await formatWaitOutput(status, assistantText, signal);
      return {
        content: [{ type: "text", text: output.text }],
        details: {
          target: params.target,
          pane_id: resolved.result.agent.pane_id,
          status,
          full_output_path: output.fullOutputPath,
        },
      };
    },
  });
}
