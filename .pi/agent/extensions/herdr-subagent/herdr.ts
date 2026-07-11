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

const StartAgentResponseSchema = Type.Object({
  id: Type.String(),
  result: Type.Object({
    agent: AgentInfoSchema,
    argv: Type.Array(Type.String()),
    type: Type.Literal("agent_started"),
  }),
});

export type StartAgentResponse = Static<typeof StartAgentResponseSchema>;

const GetAgentResponseSchema = Type.Object({
  id: Type.String(),
  result: Type.Object({
    agent: AgentInfoSchema,
    type: Type.Literal("agent_info"),
  }),
});

export type GetAgentResponse = Static<typeof GetAgentResponseSchema>;

const RunInPaneResponseSchema = Type.Undefined();
export type RunInPaneResponse = Static<typeof RunInPaneResponseSchema>;

const MovePaneToNewTabResponseSchema = Type.Object({
  id: Type.String(),
  result: Type.Object({
    move_result: Type.Object({
      changed: Type.Boolean(),
      created_tab: Type.Object({
        tab_id: Type.String(),
        workspace_id: Type.String(),
      }),
      pane: Type.Object({
        pane_id: Type.String(),
        tab_id: Type.String(),
        workspace_id: Type.String(),
      }),
    }),
    type: Type.Literal("pane_move"),
  }),
});

export type MovePaneToNewTabResponse = Static<typeof MovePaneToNewTabResponseSchema>;

const WaitResolvedResponseSchema = GetAgentResponseSchema;
const WaitChangedResponseSchema = Type.Object({
  event: Type.Literal("pane.agent_status_changed"),
  data: Type.Object({
    pane_id: Type.String(),
    agent_status: AgentStatusSchema,
    agent: Type.Optional(Type.String()),
  }),
});
const WaitForAgentStatusResponseSchema = Type.Union([
  WaitResolvedResponseSchema,
  WaitChangedResponseSchema,
]);

export type WaitForAgentStatusResponse = Static<typeof WaitForAgentStatusResponseSchema>;
export type HerdrAgentStatus = Static<typeof AgentStatusSchema>;
export type SettledStatus = "idle" | "blocked";

export interface StartAgentInput {
  name: string;
  cwd: string;
  workspaceId: string;
  tabId: string;
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

  async startAgent(
    input: StartAgentInput,
    signal: AbortSignal | undefined,
  ): Promise<StartAgentResponse> {
    const args = [
      "agent",
      "start",
      input.name,
      "--cwd",
      input.cwd,
      "--workspace",
      input.workspaceId,
      "--tab",
      input.tabId,
      "--no-focus",
      "--",
      "pi",
      ...input.piArgs,
    ];
    const result = await this.pi.exec("herdr", args, signal ? { signal } : {});
    throwForFailedCommand("herdr agent start", result);
    return parseResponse("herdr agent start", result.stdout, StartAgentResponseSchema);
  }

  async getAgent(agent: string, signal: AbortSignal | undefined): Promise<GetAgentResponse> {
    const result = await this.pi.exec("herdr", ["agent", "get", agent], signal ? { signal } : {});
    throwForFailedCommand("herdr agent get", result);
    return parseResponse("herdr agent get", result.stdout, GetAgentResponseSchema);
  }

  async runInPane(
    paneId: string,
    prompt: string,
    signal: AbortSignal | undefined,
  ): Promise<RunInPaneResponse> {
    const result = await this.pi.exec(
      "herdr",
      ["pane", "run", paneId, prompt],
      signal ? { signal } : {},
    );
    throwForFailedCommand("herdr pane run", result);
    return parseResponse("herdr pane run", result.stdout, RunInPaneResponseSchema);
  }

  async movePaneToNewTab(
    paneId: string,
    workspaceId: string,
    label: string,
    signal: AbortSignal | undefined,
  ): Promise<MovePaneToNewTabResponse> {
    const result = await this.pi.exec(
      "herdr",
      [
        "pane",
        "move",
        paneId,
        "--new-tab",
        "--workspace",
        workspaceId,
        "--label",
        label,
        "--no-focus",
      ],
      signal ? { signal } : {},
    );
    throwForFailedCommand("herdr pane move", result);
    return parseResponse("herdr pane move", result.stdout, MovePaneToNewTabResponseSchema);
  }

  async waitForAgentStatus(
    agent: string,
    status: SettledStatus,
    signal: AbortSignal | undefined,
  ): Promise<WaitForAgentStatusResponse> {
    const result = await this.pi.exec(
      "herdr",
      ["agent", "wait", agent, "--status", status],
      signal ? { signal } : {},
    );
    throwForFailedCommand("herdr agent wait", result);
    return parseResponse("herdr agent wait", result.stdout, WaitForAgentStatusResponseSchema);
  }
}
