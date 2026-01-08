import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import * as path from "node:path";

const PROTECTED_PATTERNS = [/(^|\/)\.git(\/|$)/, /(^|\/)node_modules(\/|$)/];

function isProtectedPath(filePath: string): boolean {
  const normalized = path.normalize(filePath).replace(/^\.\//, "");
  return PROTECTED_PATTERNS.some((pattern) => pattern.test(normalized));
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "write" && event.toolName !== "edit") {
      return undefined;
    }

    const filePath = event.input.path as string;

    if (isProtectedPath(filePath)) {
      if (ctx.hasUI) {
        ctx.ui.notify(
          `Blocked write to protected path: ${filePath}`,
          "warning",
        );
      }
      return { block: true, reason: `Path "${filePath}" is protected` };
    }

    return undefined;
  });
}
