import { mkdtemp, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  DEFAULT_MAX_BYTES,
  DEFAULT_MAX_LINES,
  formatSize,
  keyHint,
  SessionManager,
  truncateTail,
  type ExtensionAPI,
} from "@earendil-works/pi-coding-agent";
import { Container, Text } from "@earendil-works/pi-tui";
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
  assistantText: string,
  signal?: AbortSignal,
): Promise<{ text: string; fullOutputPath?: string }> {
  const truncated = truncateTail(assistantText, {
    maxLines: DEFAULT_MAX_LINES,
    maxBytes: DEFAULT_MAX_BYTES,
  });
  if (!truncated.truncated) return { text: assistantText };

  const tempDir = await mkdtemp(join(tmpdir(), "pi-subagent-wait-"));
  const fullOutputPath = join(tempDir, "output.log");
  await writeFile(fullOutputPath, assistantText, { encoding: "utf8", signal });

  const notice = `[Output truncated: showing the newest ${truncated.outputLines} of ${truncated.totalLines} lines (${formatSize(truncated.outputBytes)} of ${formatSize(truncated.totalBytes)}). Full output saved to: ${fullOutputPath}]`;
  return {
    text: `${notice}\n\n${truncated.content}`,
    fullOutputPath,
  };
}

const SpawnAgentParams = Type.Object({
  task_name: Type.String({
    description:
      "Short, unique name that contains only lowercase letters, numbers, and underscores. This is the agent name and the Herdr tab name.",
    pattern: "^[a-z0-9_]+$",
  }),
  message: Type.String({
    description:
      "Complete instructions for one specific task. Include all required context, file paths, constraints, and expected output.",
  }),
});

const FollowupTaskParams = Type.Object({
  target: Type.String({ description: "Task name or pane ID returned by spawn_agent." }),
  message: Type.String({ description: "More instructions for the agent." }),
});

const WaitAgentParams = Type.Object({
  target: Type.String({ description: "Task name or pane ID returned by spawn_agent." }),
});

const SUBAGENT_TOOLS = ["spawn_agent", "followup_task", "wait_agent"];

export default function (pi: ExtensionAPI): void {
  if (process.env.HERDR_ENV !== "1") return;

  const herdr = new Herdr(pi);

  pi.registerCommand("subagent", {
    description: "Toggle subagent tools",
    handler: async (_args, ctx) => {
      const active = pi.getActiveTools();
      const enabled = !SUBAGENT_TOOLS.every((tool) => active.includes(tool));
      pi.setActiveTools(
        enabled
          ? [...new Set([...active, ...SUBAGENT_TOOLS])]
          : active.filter((tool) => !SUBAGENT_TOOLS.includes(tool)),
      );
      ctx.ui.notify(`Subagent tools ${enabled ? "enabled" : "disabled"}.`, "info");
    },
  });

  pi.on("session_start", () => {
    pi.setActiveTools(pi.getActiveTools().filter((tool) => !SUBAGENT_TOOLS.includes(tool)));
  });

  pi.registerTool({
    name: "spawn_agent",
    label: "spawn_agent",
    description: [
      "Start a named Pi agent in a new background Herdr tab.",
      "The agent does not receive the parent conversation.",
      "Give the agent complete instructions for one specific task.",
      "The agent uses the parent model, reasoning level, working directory, project trust, and active tools, except collaboration tools.",
      "The agent cannot start another agent.",
      "This tool returns the task name and pane ID after the agent starts work.",
      "Use either value as the target for followup_task or wait_agent.",
    ].join(" "),
    parameters: SpawnAgentParams,
    renderCall(args, theme, context) {
      const taskName = args.task_name || "…";
      const expandHint = context.expanded
        ? ""
        : theme.fg("muted", ` (${keyHint("app.tools.expand", "to expand")})`);
      const instructions = context.expanded
        ? `\n\n${theme.fg("toolOutput", args.message || "…")}`
        : "";
      return new Text(
        theme.fg("toolTitle", theme.bold("spawn_agent ")) +
          theme.fg("accent", taskName) +
          expandHint +
          instructions,
        0,
        0,
      );
    },
    renderResult(result, _options, theme, context) {
      if (!context.isError) return new Container();

      const output = result.content
        .filter((block) => block.type === "text")
        .map((block) => block.text)
        .join("\n");
      return new Text(`\n${theme.fg("toolOutput", output)}`, 0, 0);
    },
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
      await herdr.waitForShellStartup(signal);
      await herdr.startAgent({ name: agent, paneId, piArgs }, signal);
      await herdr.promptAgent(agent, params.message, signal);
      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ task_name: agent, pane_id: paneId }),
          },
        ],
        details: {
          task_name: agent,
          pane_id: paneId,
          tab_id: tab.result.tab.tab_id,
        },
      };
    },
  });

  pi.registerTool({
    name: "followup_task",
    label: "followup_task",
    description: [
      "Send more instructions to an agent.",
      "Use the task name or pane ID returned by spawn_agent as the target.",
      "This tool returns after it delivers the instructions and detects that the agent is working.",
      "It does not wait for the agent to finish.",
    ].join(" "),
    parameters: FollowupTaskParams,
    renderCall(args, theme) {
      const target = args.target || "…";
      return new Text(
        theme.fg("toolTitle", theme.bold("followup_task ")) + theme.fg("accent", target),
        0,
        0,
      );
    },
    renderResult(result, _options, theme, context) {
      const text =
        context.lastComponent instanceof Text ? context.lastComponent : new Text("", 0, 0);
      const output = result.content
        .filter((block) => block.type === "text")
        .map((block) => block.text)
        .join("\n");
      text.setText(`\n${theme.fg("toolOutput", output)}`);
      return text;
    },
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
      "Wait until an agent is idle, done, or blocked.",
      "Use the task name or pane ID returned by spawn_agent as the target.",
      "This tool returns the latest assistant response.",
      "Use it only when your work depends on that response.",
    ].join(" "),
    parameters: WaitAgentParams,
    renderCall(args, theme, context) {
      const target = args.target || "…";
      const expandHint = context.expanded
        ? ""
        : theme.fg("muted", ` (${keyHint("app.tools.expand", "to expand")})`);
      return new Text(
        theme.fg("toolTitle", theme.bold("wait_agent ")) + theme.fg("accent", target) + expandHint,
        0,
        0,
      );
    },
    renderResult(result, { expanded }, theme, context) {
      if (!expanded && !context.isError) return new Container();

      const text =
        context.lastComponent instanceof Text ? context.lastComponent : new Text("", 0, 0);
      const output = result.content
        .filter((block) => block.type === "text")
        .map((block) => block.text)
        .join("\n");
      text.setText(`\n${theme.fg("toolOutput", output)}`);
      return text;
    },
    async execute(_toolCallId, params, signal) {
      const resolved = await herdr.waitForAgent(params.target, signal);
      const session = resolved.result.agent.agent_session;
      if (!session || session.kind !== "path" || !session.value) {
        throw new Error(`Agent ${params.target} has no session path`);
      }
      const assistantText = latestAssistantText(SessionManager.open(session.value));
      const output = await formatWaitOutput(assistantText, signal);
      return {
        content: [{ type: "text", text: output.text }],
        details: {
          target: params.target,
          pane_id: resolved.result.agent.pane_id,
          full_output_path: output.fullOutputPath,
        },
      };
    },
  });
}
