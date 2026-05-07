import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const GUIDELINE = "- Use bash for file operations like ls, rg, find";
const INSERT = "- Prefer modern shell tools: use rg instead of grep and fd instead of find";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    if (event.systemPrompt.includes(INSERT)) return;

    if (!event.systemPrompt.includes(GUIDELINE)) {
      ctx.ui.notify(
        `modern-shell-tools: expected system prompt text not found: ${GUIDELINE}`,
        "error",
      );
      return;
    }

    return {
      systemPrompt: event.systemPrompt.replace(GUIDELINE, `${GUIDELINE}\n${INSERT}`),
    };
  });
}
