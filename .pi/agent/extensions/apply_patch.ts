/**
 * apply_patch tool for pi
 *
 * Inspired by:
 * - OpenAI Codex: codex-rs/apply-patch
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { withFileMutationQueue } from "@mariozechner/pi-coding-agent";
import { Text } from "@mariozechner/pi-tui";
import { Type } from "@sinclair/typebox";
import { mkdtemp, mkdir, readFile, rm, stat, unlink, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";

const BEGIN_PATCH_MARKER = "*** Begin Patch";
const END_PATCH_MARKER = "*** End Patch";
const ADD_FILE_MARKER = "*** Add File: ";
const DELETE_FILE_MARKER = "*** Delete File: ";
const UPDATE_FILE_MARKER = "*** Update File: ";
const MOVE_TO_MARKER = "*** Move to: ";
const EOF_MARKER = "*** End of File";
const CHANGE_CONTEXT_MARKER = "@@ ";
const EMPTY_CHANGE_CONTEXT_MARKER = "@@";

const ApplyPatchParams = Type.Object({
  patch: Type.String({
    description:
      "Full apply_patch payload. Wrap edits in *** Begin Patch / *** End Patch and use Add File / Delete File / Update File hunks.",
  }),
});

type ApplyPatchParamsType = {
  patch: string;
};

type Hunk =
  | { type: "add"; path: string; contents: string }
  | { type: "delete"; path: string }
  | { type: "update"; path: string; movePath?: string; chunks: UpdateFileChunk[] };

interface UpdateFileChunk {
  changeContext?: string;
  oldLines: string[];
  newLines: string[];
  isEndOfFile: boolean;
}

interface ParsedPatch {
  patch: string;
  hunks: Hunk[];
  workdir?: string;
}

interface ApplyPatchDetails {
  added: string[];
  modified: string[];
  deleted: string[];
  changes: Array<
    | { type: "add"; path: string }
    | { type: "delete"; path: string }
    | { type: "update"; path: string; movePath?: string; unifiedDiff: string }
  >;
  cwd: string;
}

class PatchParseError extends Error {
  constructor(
    public readonly kind: "patch" | "hunk",
    message: string,
    public readonly lineNumber?: number,
  ) {
    super(message);
    this.name = "PatchParseError";
  }
}

function invalidPatch(message: string): never {
  throw new PatchParseError("patch", message);
}

function invalidHunk(message: string, lineNumber: number): never {
  throw new PatchParseError("hunk", message, lineNumber);
}

function formatError(error: unknown): string {
  if (error instanceof PatchParseError) {
    if (error.kind === "patch") return `Invalid patch: ${error.message}`;
    return `Invalid patch hunk on line ${error.lineNumber}: ${error.message}`;
  }
  if (error instanceof Error) return error.message;
  return String(error);
}

function unquotePath(value: string): string {
  const trimmed = value.trim();
  if (
    (trimmed.startsWith("'") && trimmed.endsWith("'")) ||
    (trimmed.startsWith('"') && trimmed.endsWith('"'))
  ) {
    return trimmed.slice(1, -1);
  }
  return trimmed;
}

function tryExtractPatchFromShellScript(input: string): { patch: string; workdir?: string } | null {
  const trimmed = input.trim();
  const match = trimmed.match(
    /^(?:cd\s+(?<cd>(?:'[^']*'|"[^"]*"|[^;&|\n]+?))\s*&&\s*)?(?<cmd>apply_patch|applypatch)\s*<<['"]?(?<tag>[A-Za-z_][A-Za-z0-9_]*)['"]?\s*\r?\n(?<body>[\s\S]*?)\r?\n\k<tag>\s*$/,
  );
  if (!match?.groups?.body) return null;
  return {
    patch: match.groups.body,
    workdir: match.groups.cd ? unquotePath(match.groups.cd) : undefined,
  };
}

function parsePatch(patchText: string): ParsedPatch {
  try {
    return parsePatchText(patchText, false);
  } catch (error) {
    const fromShell = tryExtractPatchFromShellScript(patchText);
    if (!fromShell) throw error;
    const parsed = parsePatchText(fromShell.patch, false);
    return { ...parsed, workdir: fromShell.workdir };
  }
}

function parsePatchText(patchText: string, lenient: boolean): ParsedPatch {
  const lines = patchText.trim().split(/\r?\n/);
  const normalizedLines = checkPatchBoundaries(lines, lenient);

  const hunks: Hunk[] = [];
  let remaining = normalizedLines.slice(1, Math.max(1, normalizedLines.length - 1));
  let lineNumber = 2;

  while (remaining.length > 0) {
    const { hunk, consumed } = parseOneHunk(remaining, lineNumber);
    hunks.push(hunk);
    lineNumber += consumed;
    remaining = remaining.slice(consumed);
  }

  return {
    patch: normalizedLines.join("\n"),
    hunks,
  };
}

function checkPatchBoundaries(lines: string[], lenient: boolean): string[] {
  try {
    checkPatchBoundariesStrict(lines);
    return lines;
  } catch (error) {
    if (!lenient) {
      const heredocBody = checkPatchBoundariesLenient(lines);
      if (!heredocBody) throw error;
      return heredocBody;
    }
    throw error;
  }
}

function checkPatchBoundariesStrict(lines: string[]): void {
  const first = lines[0]?.trim();
  const last = lines[lines.length - 1]?.trim();

  if (first !== BEGIN_PATCH_MARKER) {
    invalidPatch(`The first line of the patch must be '${BEGIN_PATCH_MARKER}'`);
  }
  if (last !== END_PATCH_MARKER) {
    invalidPatch(`The last line of the patch must be '${END_PATCH_MARKER}'`);
  }
}

function checkPatchBoundariesLenient(lines: string[]): string[] | null {
  if (lines.length < 4) return null;
  const first = lines[0];
  const last = lines[lines.length - 1];
  if ((first === "<<EOF" || first === "<<'EOF'" || first === '<<"EOF"') && last.endsWith("EOF")) {
    const inner = lines.slice(1, -1);
    checkPatchBoundariesStrict(inner);
    return inner;
  }
  return null;
}

function parseOneHunk(lines: string[], lineNumber: number): { hunk: Hunk; consumed: number } {
  const firstLine = lines[0]?.trim() ?? "";

  if (firstLine.startsWith(ADD_FILE_MARKER)) {
    const path = firstLine.slice(ADD_FILE_MARKER.length);
    let contents = "";
    let consumed = 1;
    for (const line of lines.slice(1)) {
      if (!line.startsWith("+")) break;
      contents += `${line.slice(1)}\n`;
      consumed += 1;
    }
    return { hunk: { type: "add", path, contents }, consumed };
  }

  if (firstLine.startsWith(DELETE_FILE_MARKER)) {
    const path = firstLine.slice(DELETE_FILE_MARKER.length);
    return { hunk: { type: "delete", path }, consumed: 1 };
  }

  if (firstLine.startsWith(UPDATE_FILE_MARKER)) {
    const path = firstLine.slice(UPDATE_FILE_MARKER.length);
    let remaining = lines.slice(1);
    let consumed = 1;
    let movePath: string | undefined;

    if (remaining[0]?.startsWith(MOVE_TO_MARKER)) {
      movePath = remaining[0].slice(MOVE_TO_MARKER.length);
      remaining = remaining.slice(1);
      consumed += 1;
    }

    const chunks: UpdateFileChunk[] = [];
    while (remaining.length > 0) {
      if (remaining[0].trim() === "") {
        remaining = remaining.slice(1);
        consumed += 1;
        continue;
      }
      if (remaining[0].startsWith("***")) break;

      const parsedChunk = parseUpdateFileChunk(
        remaining,
        lineNumber + consumed,
        chunks.length === 0,
      );
      chunks.push(parsedChunk.chunk);
      remaining = remaining.slice(parsedChunk.consumed);
      consumed += parsedChunk.consumed;
    }

    if (chunks.length === 0) {
      invalidHunk(`Update file hunk for path '${path}' is empty`, lineNumber);
    }

    return {
      hunk: { type: "update", path, movePath, chunks },
      consumed,
    };
  }

  invalidHunk(
    `'${firstLine}' is not a valid hunk header. Valid hunk headers: '*** Add File: {path}', '*** Delete File: {path}', '*** Update File: {path}'`,
    lineNumber,
  );
}

function parseUpdateFileChunk(
  lines: string[],
  lineNumber: number,
  allowMissingContext: boolean,
): { chunk: UpdateFileChunk; consumed: number } {
  if (lines.length === 0) {
    invalidHunk("Update hunk does not contain any lines", lineNumber);
  }

  let changeContext: string | undefined;
  let startIndex = 0;

  if (lines[0] === EMPTY_CHANGE_CONTEXT_MARKER) {
    startIndex = 1;
  } else if (lines[0].startsWith(CHANGE_CONTEXT_MARKER)) {
    changeContext = lines[0].slice(CHANGE_CONTEXT_MARKER.length);
    startIndex = 1;
  } else if (!allowMissingContext) {
    invalidHunk(
      `Expected update hunk to start with a @@ context marker, got: '${lines[0]}'`,
      lineNumber,
    );
  }

  if (startIndex >= lines.length) {
    invalidHunk("Update hunk does not contain any lines", lineNumber + 1);
  }

  const chunk: UpdateFileChunk = {
    changeContext,
    oldLines: [],
    newLines: [],
    isEndOfFile: false,
  };

  let parsedLines = 0;
  for (const line of lines.slice(startIndex)) {
    if (line === EOF_MARKER) {
      if (parsedLines === 0) {
        invalidHunk("Update hunk does not contain any lines", lineNumber + 1);
      }
      chunk.isEndOfFile = true;
      parsedLines += 1;
      break;
    }

    const prefix = line[0];
    if (prefix === undefined) {
      chunk.oldLines.push("");
      chunk.newLines.push("");
      parsedLines += 1;
      continue;
    }

    if (prefix === " ") {
      chunk.oldLines.push(line.slice(1));
      chunk.newLines.push(line.slice(1));
      parsedLines += 1;
      continue;
    }
    if (prefix === "+") {
      chunk.newLines.push(line.slice(1));
      parsedLines += 1;
      continue;
    }
    if (prefix === "-") {
      chunk.oldLines.push(line.slice(1));
      parsedLines += 1;
      continue;
    }

    if (parsedLines === 0) {
      invalidHunk(
        `Unexpected line found in update hunk: '${line}'. Every line should start with ' ' (context line), '+' (added line), or '-' (removed line)`,
        lineNumber + 1,
      );
    }
    break;
  }

  return { chunk, consumed: parsedLines + startIndex };
}

function resolvePatchPath(cwd: string, patchPath: string): string {
  return resolve(cwd, patchPath);
}

function normalizeForMatch(value: string): string {
  return value
    .trim()
    .split("")
    .map((char) => {
      switch (char) {
        case "\u2010":
        case "\u2011":
        case "\u2012":
        case "\u2013":
        case "\u2014":
        case "\u2015":
        case "\u2212":
          return "-";
        case "\u2018":
        case "\u2019":
        case "\u201A":
        case "\u201B":
          return "'";
        case "\u201C":
        case "\u201D":
        case "\u201E":
        case "\u201F":
          return '"';
        case "\u00A0":
        case "\u2002":
        case "\u2003":
        case "\u2004":
        case "\u2005":
        case "\u2006":
        case "\u2007":
        case "\u2008":
        case "\u2009":
        case "\u200A":
        case "\u202F":
        case "\u205F":
        case "\u3000":
          return " ";
        default:
          return char;
      }
    })
    .join("");
}

function seekSequence(
  lines: string[],
  pattern: string[],
  start: number,
  eof: boolean,
): number | undefined {
  if (pattern.length === 0) return start;
  if (pattern.length > lines.length) return undefined;

  const searchStart = eof ? lines.length - pattern.length : start;
  const searchEnd = lines.length - pattern.length;

  for (let i = searchStart; i <= searchEnd; i++) {
    let ok = true;
    for (let j = 0; j < pattern.length; j++) {
      if (lines[i + j] !== pattern[j]) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }

  for (let i = searchStart; i <= searchEnd; i++) {
    let ok = true;
    for (let j = 0; j < pattern.length; j++) {
      if (lines[i + j].trimEnd() !== pattern[j].trimEnd()) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }

  for (let i = searchStart; i <= searchEnd; i++) {
    let ok = true;
    for (let j = 0; j < pattern.length; j++) {
      if (lines[i + j].trim() !== pattern[j].trim()) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }

  for (let i = searchStart; i <= searchEnd; i++) {
    let ok = true;
    for (let j = 0; j < pattern.length; j++) {
      if (normalizeForMatch(lines[i + j]) !== normalizeForMatch(pattern[j])) {
        ok = false;
        break;
      }
    }
    if (ok) return i;
  }

  return undefined;
}

function computeReplacements(
  originalLines: string[],
  filePath: string,
  chunks: UpdateFileChunk[],
): Array<[number, number, string[]]> {
  const replacements: Array<[number, number, string[]]> = [];
  let lineIndex = 0;

  for (const chunk of chunks) {
    if (chunk.changeContext !== undefined) {
      const idx = seekSequence(originalLines, [chunk.changeContext], lineIndex, false);
      if (idx === undefined) {
        throw new Error(`Failed to find context '${chunk.changeContext}' in ${filePath}`);
      }
      lineIndex = idx + 1;
    }

    if (chunk.oldLines.length === 0) {
      const insertionIndex =
        originalLines.at(-1) === "" ? originalLines.length - 1 : originalLines.length;
      replacements.push([insertionIndex, 0, [...chunk.newLines]]);
      continue;
    }

    let pattern = [...chunk.oldLines];
    let newSlice = [...chunk.newLines];
    let found = seekSequence(originalLines, pattern, lineIndex, chunk.isEndOfFile);

    if (found === undefined && pattern.at(-1) === "") {
      pattern = pattern.slice(0, -1);
      if (newSlice.at(-1) === "") newSlice = newSlice.slice(0, -1);
      found = seekSequence(originalLines, pattern, lineIndex, chunk.isEndOfFile);
    }

    if (found === undefined) {
      throw new Error(
        `Failed to find expected lines in ${filePath}:\n${chunk.oldLines.join("\n")}`,
      );
    }

    replacements.push([found, pattern.length, newSlice]);
    lineIndex = found + pattern.length;
  }

  replacements.sort((a, b) => a[0] - b[0]);
  return replacements;
}

function applyReplacements(
  lines: string[],
  replacements: Array<[number, number, string[]]>,
): string[] {
  const result = [...lines];
  for (let i = replacements.length - 1; i >= 0; i--) {
    const [startIndex, oldLength, newSegment] = replacements[i];
    result.splice(startIndex, oldLength, ...newSegment);
  }
  return result;
}

async function generateUnifiedDiff(
  originalContent: string,
  newContent: string,
  pi: ExtensionAPI,
  signal?: AbortSignal,
): Promise<string> {
  if (originalContent === newContent) return "";

  const tempDir = await mkdtemp(join(tmpdir(), "pi-apply-patch-"));
  const beforePath = join(tempDir, "before.txt");
  const afterPath = join(tempDir, "after.txt");

  try {
    await writeFile(beforePath, originalContent, "utf8");
    await writeFile(afterPath, newContent, "utf8");

    const result = await pi.exec("diff", ["-U1", beforePath, afterPath], { signal });
    if (result.code === 0) return "";
    if (result.code === 1 && result.stdout) {
      const lines = result.stdout.replace(/\r\n/g, "\n").split("\n");
      if (lines[0]?.startsWith("--- ") && lines[1]?.startsWith("+++ ")) {
        lines.splice(0, 2);
      }
      let diff = lines.join("\n");
      if (diff && !diff.endsWith("\n")) diff += "\n";
      return diff;
    }
  } catch {
    // Fall through to the built-in fallback.
  } finally {
    await rm(tempDir, { recursive: true, force: true });
  }

  return simpleUnifiedDiff(originalContent, newContent);
}

function simpleUnifiedDiff(originalContent: string, newContent: string): string {
  const oldLines = originalContent.split("\n");
  const newLines = newContent.split("\n");
  const maxLength = Math.max(oldLines.length, newLines.length);

  let firstDiff = -1;
  let lastOld = -1;
  let lastNew = -1;

  for (let i = 0; i < maxLength; i++) {
    if ((oldLines[i] ?? "") !== (newLines[i] ?? "")) {
      if (firstDiff === -1) firstDiff = i;
      lastOld = i;
      lastNew = i;
    }
  }

  if (firstDiff === -1) return "";

  const startOld = Math.max(0, firstDiff - 1);
  const startNew = Math.max(0, firstDiff - 1);
  const endOld = Math.min(oldLines.length, lastOld + 2);
  const endNew = Math.min(newLines.length, lastNew + 2);

  const hunkOldCount = Math.max(0, endOld - startOld);
  const hunkNewCount = Math.max(0, endNew - startNew);

  let output = `@@ -${startOld + 1},${hunkOldCount} +${startNew + 1},${hunkNewCount} @@\n`;
  const sharedStart = Math.max(0, firstDiff - 1);
  const sharedEnd = Math.min(maxLength, Math.max(lastOld, lastNew) + 2);

  for (let i = sharedStart; i < sharedEnd; i++) {
    const oldLine = oldLines[i];
    const newLine = newLines[i];
    if (oldLine === newLine) {
      if (oldLine !== undefined) output += ` ${oldLine}\n`;
      continue;
    }
    if (oldLine !== undefined) output += `-${oldLine}\n`;
    if (newLine !== undefined) output += `+${newLine}\n`;
  }

  return output;
}

async function deriveNewContentsFromChunks(
  filePath: string,
  chunks: UpdateFileChunk[],
  pi: ExtensionAPI,
  signal?: AbortSignal,
): Promise<{ newContent: string; unifiedDiff: string }> {
  let originalContent: string;
  try {
    originalContent = await readFile(filePath, "utf8");
  } catch (error: any) {
    throw new Error(
      `Failed to read file to update ${filePath}: ${error?.message ?? String(error)}`,
    );
  }

  const originalLines = originalContent.split("\n");
  if (originalLines.at(-1) === "") originalLines.pop();

  const replacements = computeReplacements(originalLines, filePath, chunks);
  const newLines = applyReplacements(originalLines, replacements);
  if (newLines.at(-1) !== "") newLines.push("");

  const newContent = newLines.join("\n");
  const unifiedDiff = await generateUnifiedDiff(originalContent, newContent, pi, signal);
  return { newContent, unifiedDiff };
}

function collectMutationPaths(hunks: Hunk[], cwd: string): string[] {
  const paths = new Set<string>();
  for (const hunk of hunks) {
    switch (hunk.type) {
      case "add":
      case "delete":
        paths.add(resolvePatchPath(cwd, hunk.path));
        break;
      case "update":
        paths.add(resolvePatchPath(cwd, hunk.path));
        if (hunk.movePath) paths.add(resolvePatchPath(cwd, hunk.movePath));
        break;
    }
  }
  return [...paths].sort((a, b) => a.localeCompare(b));
}

async function withMutationQueues<T>(paths: string[], fn: () => Promise<T>): Promise<T> {
  const run = async (index: number): Promise<T> => {
    if (index >= paths.length) return fn();
    return withFileMutationQueue(paths[index], async () => run(index + 1));
  };
  return run(0);
}

function formatSummary(details: Pick<ApplyPatchDetails, "added" | "modified" | "deleted">): string {
  const lines = ["Success. Updated the following files:"];
  for (const path of details.added) lines.push(`A ${path}`);
  for (const path of details.modified) lines.push(`M ${path}`);
  for (const path of details.deleted) lines.push(`D ${path}`);
  return lines.join("\n");
}

async function applyHunks(
  hunks: Hunk[],
  cwd: string,
  pi: ExtensionAPI,
  signal?: AbortSignal,
): Promise<ApplyPatchDetails> {
  if (hunks.length === 0) {
    throw new Error("No files were modified.");
  }

  const details: ApplyPatchDetails = {
    added: [],
    modified: [],
    deleted: [],
    changes: [],
    cwd,
  };

  for (const hunk of hunks) {
    if (signal?.aborted) throw new Error("Cancelled");

    if (hunk.type === "add") {
      const target = resolvePatchPath(cwd, hunk.path);
      const parent = dirname(target);
      try {
        if (parent && parent !== ".") {
          await mkdir(parent, { recursive: true });
        }
      } catch (error: any) {
        throw new Error(
          `Failed to create parent directories for ${target}: ${error?.message ?? String(error)}`,
        );
      }
      try {
        await writeFile(target, hunk.contents, "utf8");
      } catch (error: any) {
        throw new Error(`Failed to write file ${target}: ${error?.message ?? String(error)}`);
      }
      details.added.push(hunk.path);
      details.changes.push({ type: "add", path: hunk.path });
      continue;
    }

    if (hunk.type === "delete") {
      const target = resolvePatchPath(cwd, hunk.path);
      try {
        const fileStat = await stat(target);
        if (fileStat.isDirectory()) {
          throw new Error("path is a directory");
        }
        await unlink(target);
      } catch (error: any) {
        throw new Error(`Failed to delete file ${target}: ${error?.message ?? String(error)}`);
      }
      details.deleted.push(hunk.path);
      details.changes.push({ type: "delete", path: hunk.path });
      continue;
    }

    const source = resolvePatchPath(cwd, hunk.path);
    const { newContent, unifiedDiff } = await deriveNewContentsFromChunks(
      source,
      hunk.chunks,
      pi,
      signal,
    );

    if (hunk.movePath) {
      const destination = resolvePatchPath(cwd, hunk.movePath);
      const parent = dirname(destination);
      try {
        if (parent && parent !== ".") {
          await mkdir(parent, { recursive: true });
        }
      } catch (error: any) {
        throw new Error(
          `Failed to create parent directories for ${destination}: ${error?.message ?? String(error)}`,
        );
      }
      try {
        await writeFile(destination, newContent, "utf8");
      } catch (error: any) {
        throw new Error(`Failed to write file ${destination}: ${error?.message ?? String(error)}`);
      }
      try {
        const sourceStat = await stat(source);
        if (sourceStat.isDirectory()) {
          throw new Error("path is a directory");
        }
        await unlink(source);
      } catch (error: any) {
        throw new Error(`Failed to remove original ${source}: ${error?.message ?? String(error)}`);
      }
      details.modified.push(hunk.movePath);
      details.changes.push({
        type: "update",
        path: hunk.path,
        movePath: hunk.movePath,
        unifiedDiff,
      });
      continue;
    }

    try {
      await writeFile(source, newContent, "utf8");
    } catch (error: any) {
      throw new Error(`Failed to write file ${source}: ${error?.message ?? String(error)}`);
    }
    details.modified.push(hunk.path);
    details.changes.push({ type: "update", path: hunk.path, unifiedDiff });
  }

  return details;
}

function summarizePatchForRender(patch: string): string[] {
  try {
    const parsed = parsePatch(patch);
    return parsed.hunks.map((hunk) => {
      if (hunk.type === "add") return `A ${hunk.path}`;
      if (hunk.type === "delete") return `D ${hunk.path}`;
      if (hunk.movePath) return `M ${hunk.path} → ${hunk.movePath}`;
      return `M ${hunk.path}`;
    });
  } catch {
    return [];
  }
}

export default function applyPatchExtension(pi: ExtensionAPI) {
  pi.registerTool({
    name: "apply_patch",
    label: "Apply Patch",
    description:
      "Apply Codex-style file patches. The patch must use *** Begin Patch / *** End Patch with Add File, Delete File, Update File, optional Move to, @@ hunks, diff lines prefixed with space/-/+ and optional *** End of File.",
    promptSnippet: "Apply file-oriented patches using Codex apply_patch syntax.",
    promptGuidelines: [
      "Use apply_patch when you can express precise edits as a multi-file patch rather than a series of edit/write calls.",
      "Wrap the payload in *** Begin Patch and *** End Patch.",
      "Use *** Add File:, *** Delete File:, or *** Update File:. For renames after Update File, add *** Move to:.",
      "Within @@ hunks, context lines start with a space, removals with -, additions with +. New file contents also require + prefixes.",
    ],
    parameters: ApplyPatchParams,
    prepareArguments(args) {
      if (typeof args === "string") return { patch: args };
      if (!args || typeof args !== "object") return args as ApplyPatchParamsType;
      const input = args as { patch?: string; patchText?: string };
      if (typeof input.patch !== "string" && typeof input.patchText === "string") {
        return { patch: input.patchText };
      }
      return args as ApplyPatchParamsType;
    },

    async execute(_toolCallId, params: ApplyPatchParamsType, signal, _onUpdate, ctx) {
      try {
        const parsed = parsePatch(params.patch);
        const effectiveCwd = resolve(ctx.cwd, parsed.workdir ?? ".");

        const paths = collectMutationPaths(parsed.hunks, effectiveCwd);
        const details = await withMutationQueues(paths, async () =>
          applyHunks(parsed.hunks, effectiveCwd, pi, signal),
        );
        const summary = formatSummary(details);
        return {
          content: [{ type: "text", text: summary }],
          details,
        };
      } catch (error) {
        return {
          content: [{ type: "text", text: formatError(error) }],
          details: {},
          isError: true,
        };
      }
    },

    renderCall(args, theme) {
      const patch = typeof args.patch === "string" ? args.patch : "";
      const summary = summarizePatchForRender(patch);
      let text = theme.fg("toolTitle", theme.bold("apply_patch"));
      if (summary.length > 0) {
        text += `\n${theme.fg("dim", summary.join("\n"))}`;
      } else if (patch) {
        text += `\n${theme.fg("warning", "(unable to parse patch preview)")}`;
      }
      return new Text(text, 0, 0);
    },

    renderResult(result, _options, theme) {
      const details = result.details as ApplyPatchDetails | undefined;
      if (
        !details ||
        !Array.isArray(details.added) ||
        !Array.isArray(details.modified) ||
        !Array.isArray(details.deleted)
      ) {
        const first = result.content[0];
        return new Text(first?.type === "text" ? first.text : "", 0, 0);
      }
      const summary = formatSummary(details);
      return new Text(theme.fg("success", summary), 0, 0);
    },
  });
}
