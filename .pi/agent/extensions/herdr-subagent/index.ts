import { randomUUID } from "node:crypto";
import * as fs from "node:fs";
import * as path from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { StringEnum, Type, type ModelThinkingLevel } from "@earendil-works/pi-ai";
import {
  buildContextEntries,
  formatSize,
  parseSessionEntries,
  truncateTail,
  type ExtensionAPI,
  type ExtensionContext,
  type SessionEntry,
} from "@earendil-works/pi-coding-agent";

const TOOL_NAMES = new Set(["subagent", "subagent_status", "subagent_wait", "subagent_send"]);
const THINKING = [
  "off",
  "minimal",
  "low",
  "medium",
  "high",
  "xhigh",
  "max",
] satisfies ModelThinkingLevel[];
const MISSING = "Agent not found or no longer running";
type PublicStatus = "unknown" | "working" | "blocked" | "idle";
type AgentInfo = Record<string, any> & {
  name?: string;
  agent_status?: string;
  pane_id?: string;
};

function textResult(value: unknown, details: unknown = value) {
  return {
    content: [
      {
        type: "text" as const,
        text: typeof value === "string" ? value : JSON.stringify(value, null, 2),
      },
    ],
    details,
  };
}

function parseJson(stdout: string, operation: string): any {
  try {
    return JSON.parse(stdout);
  } catch (error) {
    throw new Error(
      `${operation} returned invalid JSON: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
}

async function herdr(
  pi: ExtensionAPI,
  args: string[],
  options: { signal?: AbortSignal; timeout?: number } = {},
) {
  const result = await pi.exec("herdr", args, options);
  if (result.code !== 0) {
    const message = result.stderr.trim() || result.stdout.trim() || `exit code ${result.code}`;
    throw new Error(`herdr ${args.slice(0, 2).join(" ")} failed: ${message}`);
  }
  return result.stdout.trim()
    ? parseJson(result.stdout, `herdr ${args.slice(0, 2).join(" ")}`)
    : undefined;
}

function ownerPrefix(ctx: ExtensionContext): string {
  return `subagent-${ctx.sessionManager.getSessionId()}-`;
}
function assertOwned(name: string, ctx: ExtensionContext) {
  if (!name.startsWith(ownerPrefix(ctx))) throw new Error(MISSING);
}
function normalizeStatus(status: unknown): PublicStatus {
  if (status === "done" || status === "idle") return "idle";
  if (status === "working" || status === "blocked") return status;
  return "unknown";
}
function agentName(agent: AgentInfo): string | undefined {
  return typeof agent.name === "string" ? agent.name : undefined;
}
function publicAgent(agent: AgentInfo) {
  return {
    agent: agentName(agent),
    status: normalizeStatus(agent.agent_status),
    paneId: agent.pane_id,
    tabId: agent.tab_id,
    workspaceId: agent.workspace_id,
    cwd: agent.cwd,
    ...(agent.agent_session ? { session: agent.agent_session } : {}),
  };
}

async function listOwned(pi: ExtensionAPI, ctx: ExtensionContext): Promise<AgentInfo[]> {
  const json = await herdr(pi, ["agent", "list"], { timeout: 10_000 });
  const agents = json?.result?.agents;
  if (!Array.isArray(agents))
    throw new Error("herdr agent list response did not contain result.agents");
  const prefix = ownerPrefix(ctx);
  return agents.filter((a: any) => a && agentName(a)?.startsWith(prefix));
}

async function getOwned(
  pi: ExtensionAPI,
  name: string,
  ctx: ExtensionContext,
  signal?: AbortSignal,
): Promise<AgentInfo> {
  assertOwned(name, ctx);
  const json = await herdr(pi, ["agent", "get", name], {
    ...(signal ? { signal } : {}),
    timeout: 10_000,
  });
  const agent = json?.result?.agent;
  if (!agent || agentName(agent) !== name) throw new Error(MISSING);
  return agent;
}

function qualified(model: { provider: string; id: string }) {
  return `${model.provider}/${model.id}`;
}
function allowedModels(ctx: ExtensionContext) {
  const models = ctx.modelRegistry.getAvailable().filter((m) => /^gpt-5\.6-/.test(m.id));
  if (ctx.model) models.unshift(ctx.model);
  return [...new Map(models.map((m) => [qualified(m), m])).values()];
}

function getPiInvocation(args: string[]): { command: string; args: string[] } {
  const currentScript = process.argv[1];
  const isBunVirtualScript = currentScript?.startsWith("/$bunfs/root/");
  if (currentScript && !isBunVirtualScript && fs.existsSync(currentScript)) {
    return { command: process.execPath, args: [currentScript, ...args] };
  }
  const execName = path.basename(process.execPath).toLowerCase();
  if (!/^(node|bun)(\.exe)?$/.test(execName)) return { command: process.execPath, args };
  return { command: "pi", args };
}

function sleep(ms: number, signal?: AbortSignal) {
  return delay(ms, undefined, signal ? { signal } : undefined);
}

interface AssistantResult {
  entryId?: string;
  response?: string;
  stopReason?: string;
  error?: string;
}

function getLatestAssistantResult(jsonl: string): AssistantResult | undefined {
  const entries = parseSessionEntries(jsonl).filter(
    (entry): entry is SessionEntry => entry.type !== "session",
  );
  const entry = buildContextEntries(entries).findLast(
    (candidate) => candidate.type === "message" && candidate.message.role === "assistant",
  );
  if (!entry || entry.type !== "message" || entry.message.role !== "assistant") return undefined;

  const message = entry.message;
  const text = message.content
    .filter((part) => part.type === "text")
    .map((part) => part.text)
    .join("\n")
    .trim();
  return {
    entryId: entry.id,
    stopReason: message.stopReason,
    ...(text ? { response: text } : {}),
    ...(message.errorMessage ? { error: message.errorMessage } : {}),
  };
}

async function readAssistantResult(
  agent: AgentInfo,
  signal?: AbortSignal,
): Promise<AssistantResult> {
  if (signal?.aborted) throw new Error("Subagent wait cancelled");
  const session = agent.agent_session;
  const sessionPath =
    session?.kind === "path" && typeof session.value === "string" ? session.value : undefined;
  if (!sessionPath) throw new Error("Subagent session is not available yet");
  let jsonl: string;
  try {
    jsonl = await fs.promises.readFile(sessionPath, "utf8");
  } catch (error: unknown) {
    if (error && typeof error === "object" && "code" in error && error.code === "ENOENT")
      throw new Error(MISSING);
    throw new Error(
      `Could not read subagent session: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
  if (signal?.aborted) throw new Error("Subagent wait cancelled");
  const result = getLatestAssistantResult(jsonl);
  if (!result) return {};
  if (!result.response) return result;
  const cut = truncateTail(result.response);
  const response = cut.truncated
    ? `${cut.content}\n\n[Response truncated: showing newest ${cut.outputLines}/${cut.totalLines} lines (${formatSize(cut.outputBytes)}/${formatSize(cut.totalBytes)}).]`
    : cut.content;
  return { ...result, response };
}

export default function herdrSubagents(pi: ExtensionAPI) {
  if (process.env.HERDR_ENV !== "1") return;
  let preflight: Promise<void> | undefined;
  const pendingResults = new Map<string, { baselineEntryId?: string }>();

  async function ensurePreflight(signal?: AbortSignal) {
    if (!preflight) {
      const pending = (async () => {
        const result = await pi.exec("herdr", ["integration", "status"], {
          ...(signal ? { signal } : {}),
          timeout: 10_000,
        });
        if (result.code !== 0 || !/^pi:\s+current\s+\(v\d+\)/m.test(result.stdout)) {
          throw new Error(
            "Herdr Pi lifecycle integration is not installed/current. Run `herdr integration install pi` and reload Pi.",
          );
        }
      })();
      preflight = pending;
      pending.catch(() => {
        if (preflight === pending) preflight = undefined;
      });
    }
    return preflight;
  }

  async function waitForSettledStatus(
    name: string,
    timeoutMs: number,
    signal?: AbortSignal,
  ): Promise<boolean> {
    const controller = new AbortController();
    const waitSignal = signal ? AbortSignal.any([signal, controller.signal]) : controller.signal;
    try {
      await Promise.any(
        (["idle", "blocked"] as const).map((status) =>
          herdr(pi, ["agent", "wait", name, "--status", status, "--timeout", String(timeoutMs)], {
            signal: waitSignal,
            timeout: timeoutMs + 2_000,
          }),
        ),
      );
      return true;
    } catch (error) {
      if (signal?.aborted) throw new Error("Subagent wait cancelled");
      if (error instanceof AggregateError) {
        const failures = error.errors.filter(
          (failure) =>
            !(failure instanceof Error) ||
            !failure.message.includes("timed out waiting for agent status change"),
        );
        if (failures.length === 0) return false;
        const failure = failures[0];
        throw failure instanceof Error ? failure : new Error(String(failure));
      }
      throw error;
    } finally {
      controller.abort();
    }
  }

  async function moveWithRetry(
    paneId: string,
    workspaceId: string,
    name: string,
    signal?: AbortSignal,
  ) {
    const failures: string[] = [];
    for (let attempt = 0; attempt < 3; attempt++) {
      if (signal?.aborted) throw new Error("Subagent spawn cancelled");
      if (attempt) await sleep(attempt === 1 ? 100 : 250, signal);
      try {
        return await herdr(
          pi,
          [
            "pane",
            "move",
            paneId,
            "--new-tab",
            "--workspace",
            workspaceId,
            "--label",
            name,
            "--no-focus",
          ],
          { ...(signal ? { signal } : {}), timeout: 10_000 },
        );
      } catch (error) {
        failures.push(error instanceof Error ? error.message : String(error));
      }
    }
    await pi
      .exec("herdr", ["pane", "send-keys", paneId, "Esc"], { timeout: 5_000 })
      .catch(() => undefined);
    throw new Error(
      `Created ${name} in pane ${paneId}, but placement failed after 3 attempts. Pane was preserved. Failures: ${failures.join(" | ")}`,
    );
  }

  pi.registerTool({
    name: "subagent",
    label: "Subagent",
    description:
      "Spawn a persistent subagent asynchronously. Use status, wait, and send to coordinate it.",
    parameters: Type.Object({
      prompt: Type.String({
        description: "Explicit text task for the child",
      }),
      model: Type.Optional(
        Type.String({
          description: "Qualified provider/model; defaults to the current model",
        }),
      ),
      thinking: Type.Optional(
        StringEnum(THINKING, {
          description: "Defaults to the parent's current thinking level",
        }),
      ),
    }),
    async execute(_id, params, signal, _update, execCtx) {
      await ensurePreflight(signal);
      if (signal?.aborted) throw new Error("Subagent spawn cancelled");
      const workspace = process.env.HERDR_WORKSPACE_ID;
      const tab = process.env.HERDR_TAB_ID;
      if (!workspace || !tab)
        throw new Error("Herdr did not inject HERDR_WORKSPACE_ID/HERDR_TAB_ID into this pane");

      const live = allowedModels(execCtx);
      const selectedName = params.model ?? (execCtx.model ? qualified(execCtx.model) : undefined);
      if (!selectedName) throw new Error("No current model is selected; specify an allowed model");
      if (!live.some((m) => qualified(m) === selectedName))
        throw new Error(`Model is not currently allowed/authenticated: ${selectedName}`);
      const thinking = params.thinking ?? pi.getThinkingLevel();
      const name = `${ownerPrefix(execCtx)}${randomUUID().slice(0, 8)}`;
      const tools = pi.getActiveTools().filter((tool) => !TOOL_NAMES.has(tool));
      pendingResults.set(name, {});
      const childArgs = [
        "--name",
        name,
        "--model",
        selectedName,
        "--thinking",
        thinking,
        execCtx.isProjectTrusted() ? "--approve" : "--no-approve",
      ];
      if (tools.length) childArgs.push("--tools", tools.join(","));
      else childArgs.push("--no-tools");
      childArgs.push(`Task:\n${params.prompt}`);
      const invocation = getPiInvocation(childArgs);
      let paneId: string | undefined;
      try {
        const started = await herdr(
          pi,
          [
            "agent",
            "start",
            name,
            "--cwd",
            execCtx.cwd,
            "--workspace",
            workspace,
            "--tab",
            tab,
            "--no-focus",
            "--",
            invocation.command,
            ...invocation.args,
          ],
          { ...(signal ? { signal } : {}), timeout: 20_000 },
        );
        const startedAgent = started?.result?.agent;
        paneId = startedAgent?.pane_id;
        if (typeof paneId !== "string")
          throw new Error(`Herdr created ${name} but did not return result.agent.pane_id`);
        const moved = await moveWithRetry(paneId, workspace, name, signal);
        const pane = moved?.result?.move_result?.pane;
        if (typeof pane?.pane_id !== "string" || typeof pane.tab_id !== "string") {
          throw new Error(`Herdr moved ${name} but did not return result.move_result.pane`);
        }
        return textResult({
          agent: name,
          paneId: pane.pane_id,
          tabId: pane.tab_id,
          model: selectedName,
          thinking,
          status: normalizeStatus(startedAgent.agent_status),
        });
      } catch (error) {
        if (signal?.aborted) {
          let targetPane = paneId;
          if (!targetPane) {
            const json = await herdr(pi, ["agent", "get", name], {
              timeout: 5_000,
            }).catch(() => undefined);
            targetPane = json?.result?.agent?.pane_id;
          }
          if (typeof targetPane === "string") {
            await pi
              .exec("herdr", ["pane", "close", targetPane], { timeout: 5_000 })
              .catch(() => undefined);
          }
          pendingResults.delete(name);
          throw new Error("Subagent spawn cancelled");
        }
        if (!paneId) pendingResults.delete(name);
        throw error;
      }
    },
  });

  pi.registerTool({
    name: "subagent_status",
    label: "Subagent Status",
    description:
      "Get lifecycle and location metadata for one subagent, or list all live subagents when agent is omitted.",
    parameters: Type.Object({
      agent: Type.Optional(Type.String({ description: "Subagent name; omit to list all" })),
    }),
    async execute(_id, params, signal, _update, ctx) {
      if (params.agent !== undefined) {
        return textResult(publicAgent(await getOwned(pi, params.agent, ctx, signal)));
      }
      const data = (await listOwned(pi, ctx)).map(publicAgent);
      const raw = JSON.stringify(data, null, 2);
      const cut = truncateTail(raw);
      const text = cut.truncated
        ? `${cut.content}\n\n[List truncated: showing ${cut.outputLines}/${cut.totalLines} lines (${formatSize(cut.outputBytes)}/${formatSize(cut.totalBytes)}).]`
        : cut.content;
      return textResult(text, data);
    },
  });
  pi.registerTool({
    name: "subagent_send",
    label: "Subagent Send",
    description: "Send a prompt or steering message to a subagent.",
    parameters: Type.Object({ agent: Type.String(), prompt: Type.String() }),
    async execute(_id, params, signal, _update, ctx) {
      const agent = await getOwned(pi, params.agent, ctx, signal);
      const status = normalizeStatus(agent.agent_status);
      if (status === "unknown")
        throw new Error(
          "Agent status is unknown; refusing delivery because prompt semantics are uncertain",
        );
      if (typeof agent.pane_id !== "string") throw new Error(MISSING);
      const baseline = await readAssistantResult(agent, signal);
      const previousPending = pendingResults.get(params.agent);
      pendingResults.set(
        params.agent,
        baseline.entryId ? { baselineEntryId: baseline.entryId } : {},
      );
      try {
        await herdr(pi, ["pane", "run", agent.pane_id, params.prompt], {
          ...(signal ? { signal } : {}),
          timeout: 10_000,
        });
      } catch (error) {
        if (previousPending) pendingResults.set(params.agent, previousPending);
        else pendingResults.delete(params.agent);
        throw error;
      }
      return textResult({ agent: params.agent, status, delivered: true });
    },
  });
  pi.registerTool({
    name: "subagent_wait",
    label: "Subagent Wait",
    description:
      "Wait until a subagent becomes idle or blocked, then return its final message. A timeout is a normal result.",
    parameters: Type.Object({
      agent: Type.String(),
      timeoutMs: Type.Optional(Type.Integer({ minimum: 1, maximum: 3_600_000 })),
    }),
    async execute(_id, params, signal, _update, ctx) {
      const timeoutMs = params.timeoutMs ?? 300_000;
      if (!Number.isInteger(timeoutMs) || timeoutMs <= 0 || timeoutMs > 3_600_000) {
        throw new Error("timeoutMs must be a positive integer and at most 3600000");
      }
      const deadline = Date.now() + timeoutMs;
      let agent = await getOwned(pi, params.agent, ctx, signal);
      let status = normalizeStatus(agent.agent_status);

      const tryCompletion = async () => {
        if (status !== "idle" && status !== "blocked") return undefined;
        const pending = pendingResults.get(params.agent);
        let completion: AssistantResult;
        try {
          completion = await readAssistantResult(agent, signal);
        } catch (error) {
          if (
            pending &&
            error instanceof Error &&
            (error.message === MISSING || error.message === "Subagent session is not available yet")
          ) {
            return undefined;
          }
          throw error;
        }
        if (pending && (!completion.entryId || completion.entryId === pending.baselineEntryId)) {
          return undefined;
        }
        pendingResults.delete(params.agent);
        return textResult({
          agent: params.agent,
          status,
          message: completion.error ?? completion.response ?? completion.stopReason,
        });
      };

      let completionResult = await tryCompletion();
      if (completionResult) return completionResult;

      // A just-delivered prompt can remain visibly idle until Pi starts its next turn.
      // Do not let an idle status return the assistant message captured before delivery.
      while (pendingResults.has(params.agent) && status !== "working") {
        const remaining = deadline - Date.now();
        if (remaining <= 0) return textResult({ agent: params.agent, status: "timeout" });
        await sleep(Math.min(100, remaining), signal).catch(() => {
          throw new Error("Subagent wait cancelled");
        });
        agent = await getOwned(pi, params.agent, ctx, signal);
        status = normalizeStatus(agent.agent_status);
        completionResult = await tryCompletion();
        if (completionResult) return completionResult;
      }
      if (signal?.aborted) throw new Error("Subagent wait cancelled");

      const remaining = deadline - Date.now();
      if (remaining <= 0) return textResult({ agent: params.agent, status: "timeout" });
      if (!(await waitForSettledStatus(params.agent, remaining, signal))) {
        return textResult({ agent: params.agent, status: "timeout" });
      }

      agent = await getOwned(pi, params.agent, ctx, signal);
      status = normalizeStatus(agent.agent_status);
      completionResult = await tryCompletion();
      while (!completionResult && (status === "idle" || status === "blocked")) {
        const flushRemaining = deadline - Date.now();
        if (flushRemaining <= 0) return textResult({ agent: params.agent, status: "timeout" });
        await sleep(Math.min(50, flushRemaining), signal).catch(() => {
          throw new Error("Subagent wait cancelled");
        });
        agent = await getOwned(pi, params.agent, ctx, signal);
        status = normalizeStatus(agent.agent_status);
        completionResult = await tryCompletion();
      }
      if (completionResult) return completionResult;
      return textResult({ agent: params.agent, status });
    },
  });
}
