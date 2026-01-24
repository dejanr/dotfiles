/**
 * Permission Gate Extension
 *
 * Prompts for confirmation before running potentially dangerous bash commands.
 * Patterns checked: rm -rf, sudo, chmod/chown 777, git push, gh/glab repo management
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  const dangerousPatterns = [
    // Destructive file operations
    /\brm\s+(-rf?|--recursive)/i,
    /\bsudo\b/i,
    /\b(chmod|chown)\b.*777/i,

    // Git push operations
    /\bgit\s+push\b/i,
    /\bgit\s+push\s+--force/i,
    /\bgit\s+push\s+-f\b/i,

    // GitHub CLI repo management
    /\bgh\s+repo\s+(create|delete|rename|archive|unarchive|edit)\b/i,
    /\bgh\s+repo\s+set-default\b/i,
    /\bgh\s+repo\s+deploy-key\s+(add|delete)\b/i,
    /\bgh\s+secret\s+(set|delete|remove)\b/i,
    /\bgh\s+variable\s+(set|delete|remove)\b/i,
    /\bgh\s+release\s+(create|delete|edit)\b/i,
    /\bgh\s+pr\s+merge\b/i,
    /\bgh\s+pr\s+close\b/i,
    /\bgh\s+issue\s+close\b/i,
    /\bgh\s+issue\s+delete\b/i,

    // GitLab CLI repo management
    /\bglab\s+repo\s+(create|delete|archive|unarchive)\b/i,
    /\bglab\s+mr\s+merge\b/i,
    /\bglab\s+mr\s+close\b/i,
    /\bglab\s+issue\s+close\b/i,
    /\bglab\s+issue\s+delete\b/i,
    /\bglab\s+release\s+(create|delete)\b/i,
    /\bglab\s+variable\s+(set|delete|update)\b/i,
  ];

  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return undefined;

    const command = event.input.command as string;
    const isDangerous = dangerousPatterns.some((p) => p.test(command));

    if (isDangerous) {
      if (!ctx.hasUI) {
        // In non-interactive mode, block by default
        return { block: true, reason: "Dangerous command blocked (no UI for confirmation)" };
      }

      const choice = await ctx.ui.select(`⚠️ Dangerous command:\n\n  ${command}\n\nAllow?`, [
        "Yes",
        "No",
      ]);

      if (choice !== "Yes") {
        return { block: true, reason: "Blocked by user" };
      }
    }

    return undefined;
  });
}
