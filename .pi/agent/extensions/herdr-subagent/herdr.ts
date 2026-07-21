import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type, type Static, type TSchema } from "typebox";
import { Check } from "typebox/value";

const AgentStatusSchema = Type.Union([
  Type.Literal("idle"),
  Type.Literal("working"),
  Type.Literal("blocked"),
  Type.Literal("unknown"),
  Type.Literal("done"),
]);

const AgentSessionSchema = Type.Object({
  agent: Type.String(),
  kind: Type.String(),
  source: Type.String(),
  value: Type.String(),
});

const AgentInfoSchema = Type.Object({
  agent_status: AgentStatusSchema,
  pane_id: Type.String(),
  agent: Type.Optional(Type.String()),
  name: Type.Optional(Type.String()),
  agent_session: Type.Optional(AgentSessionSchema),
});

const PaneInfoSchema = Type.Object({
  pane_id: Type.String(),
  tab_id: Type.String(),
  workspace_id: Type.String(),
});

const TabInfoSchema = Type.Object({
  tab_id: Type.String(),
  workspace_id: Type.String(),
});

const CreateTabResponseSchema = Type.Object({
  id: Type.String(),
  result: Type.Object({
    root_pane: PaneInfoSchema,
    tab: TabInfoSchema,
    type: Type.Literal("tab_created"),
  }),
});

export type CreateTabResponse = Static<typeof CreateTabResponseSchema>;

const StartAgentResponseSchema = Type.Object({
  id: Type.String(),
  result: Type.Object({
    agent: AgentInfoSchema,
    argv: Type.Array(Type.String()),
    type: Type.Literal("agent_started"),
  }),
});

export type StartAgentResponse = Static<typeof StartAgentResponseSchema>;

const PaneProcessInfoResponseSchema = Type.Object({
  id: Type.String(),
  result: Type.Object({
    process_info: Type.Object({
      pane_id: Type.String(),
      shell_pid: Type.Optional(Type.Integer()),
      foreground_process_group_id: Type.Optional(Type.Integer()),
      foreground_processes: Type.Optional(
        Type.Array(
          Type.Object({
            pid: Type.Integer(),
            name: Type.String(),
          }),
        ),
      ),
    }),
    type: Type.Literal("pane_process_info"),
  }),
});

const PromptAgentResponseSchema = Type.Object({
  id: Type.String(),
  result: Type.Object({
    agent: AgentInfoSchema,
    type: Type.Literal("agent_prompted"),
  }),
});

export type PromptAgentResponse = Static<typeof PromptAgentResponseSchema>;

const WaitForAgentResponseSchema = Type.Object({
  id: Type.String(),
  result: Type.Object({
    agent: AgentInfoSchema,
    type: Type.Literal("agent_info"),
  }),
});

export type WaitForAgentResponse = Static<typeof WaitForAgentResponseSchema>;
export interface CreateTabInput {
  cwd: string;
  label: string;
  workspaceId: string;
}

export interface StartAgentInput {
  name: string;
  paneId: string;
  piArgs: string[];
}

function parseResponse<TSchemaValue extends TSchema>(
  command: string,
  stdout: string,
  schema: TSchemaValue,
): Static<TSchemaValue> {
  let value: unknown;
  if (stdout.trim() === "") {
    value = undefined;
  } else {
    try {
      value = JSON.parse(stdout);
    } catch (error) {
      throw new Error(`Invalid JSON from ${command}: ${String(error)}`);
    }
  }
  if (!Check(schema, value)) {
    throw new Error(`Invalid response from ${command}`);
  }
  return value;
}

function throwForFailedCommand(command: string, result: { code: number; stderr: string }): void {
  if (result.code !== 0) {
    throw new Error(
      `${command} failed (${result.code}): ${result.stderr.trim() || "unknown error"}`,
    );
  }
}

export class Herdr {
  private readonly pi: ExtensionAPI;

  constructor(pi: ExtensionAPI) {
    this.pi = pi;
  }

  async createTab(
    input: CreateTabInput,
    signal: AbortSignal | undefined,
  ): Promise<CreateTabResponse> {
    const args = [
      "tab",
      "create",
      "--workspace",
      input.workspaceId,
      "--cwd",
      input.cwd,
      "--label",
      input.label,
      "--no-focus",
    ];
    const result = await this.pi.exec("herdr", args, signal ? { signal } : {});
    throwForFailedCommand("herdr tab create", result);
    return parseResponse("herdr tab create", result.stdout, CreateTabResponseSchema);
  }

  async waitForShell(paneId: string, signal: AbortSignal | undefined): Promise<void> {
    // Work around Herdr 0.7.5 checking shell availability before agent start's timeout begins.
    while (true) {
      const result = await this.pi.exec(
        "herdr",
        ["pane", "process-info", "--pane", paneId],
        signal ? { signal } : {},
      );
      throwForFailedCommand("herdr pane process-info", result);
      const response = parseResponse(
        "herdr pane process-info",
        result.stdout,
        PaneProcessInfoResponseSchema,
      );
      const info = response.result.process_info;
      const processes = info.foreground_processes ?? [];
      const shell = processes.length === 1 ? processes[0] : undefined;
      if (
        info.shell_pid !== undefined &&
        info.foreground_process_group_id === info.shell_pid &&
        shell?.pid === info.shell_pid
      ) {
        return;
      }
    }
  }

  async startAgent(
    input: StartAgentInput,
    signal: AbortSignal | undefined,
  ): Promise<StartAgentResponse> {
    const args = [
      "agent",
      "start",
      input.name,
      "--kind",
      "pi",
      "--pane",
      input.paneId,
      "--",
      ...input.piArgs,
    ];
    const result = await this.pi.exec("herdr", args, signal ? { signal } : {});
    throwForFailedCommand("herdr agent start", result);
    return parseResponse("herdr agent start", result.stdout, StartAgentResponseSchema);
  }

  async promptAgent(
    agent: string,
    prompt: string,
    signal: AbortSignal | undefined,
  ): Promise<PromptAgentResponse> {
    const result = await this.pi.exec(
      "herdr",
      ["agent", "prompt", agent, prompt, "--wait", "--until", "working"],
      signal ? { signal } : {},
    );
    throwForFailedCommand("herdr agent prompt", result);
    return parseResponse("herdr agent prompt", result.stdout, PromptAgentResponseSchema);
  }

  async waitForAgent(
    agent: string,
    signal: AbortSignal | undefined,
  ): Promise<WaitForAgentResponse> {
    const result = await this.pi.exec("herdr", ["agent", "wait", agent], signal ? { signal } : {});
    throwForFailedCommand("herdr agent wait", result);
    return parseResponse("herdr agent wait", result.stdout, WaitForAgentResponseSchema);
  }
}
