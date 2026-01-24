/**
 * Commit Command
 *
 * Branches into a new session to create git commits with user approval.
 * The new session is linked to the parent for context tracking.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const COMMIT_PROMPT = `# Commit Changes

You are tasked with creating git commits for the changes in this repository.

## Process:

1. **Analyze the changes:**
   - Run \`git status\` to see current changes
   - Run \`git diff\` to understand the modifications
   - Consider whether changes should be one commit or multiple logical commits
   - Look into both staged and unstaged files

2. **Plan your commit(s):**
   - Identify which files belong together
   - Draft clear, descriptive commit messages
   - Use imperative mood in commit messages
   - Focus on why the changes were made, not just what

3. **Present your plan to the user:**
   - List the files you plan to add for each commit
   - Show the commit message(s) you'll use
   - Ask: "I plan to create [N] commit(s) with these changes. Shall I proceed?"

4. **Execute upon confirmation:**
   - Use \`git add\` with specific files (never use \`-A\` or \`.\`)
   - Create commits with your planned messages
   - Show the result with \`git log --oneline -n [number]\`

## Important:
- **NEVER add co-author information or Claude attribution**
- Commits should be authored solely by the user
- Do not include any "Generated with Claude" messages
- Do not add "Co-Authored-By" lines
- Write commit messages as if the user wrote them

## Remember:
- Group related changes together
- Keep commits focused and atomic when possible
- The user trusts your judgment - they asked you to commit`;

export default function (pi: ExtensionAPI) {
  pi.registerCommand("commit-all", {
    description: "Branch into new session to create git commits",
    handler: async (_args, ctx) => {
      try {
        const currentSessionFile = ctx.sessionManager.getSessionFile();

        const result = await ctx.newSession({
          parentSession: currentSessionFile ?? undefined,
        });

        if (result.cancelled) {
          ctx.ui.notify("Cancelled", "info");
          return;
        }

        await pi.sendUserMessage(COMMIT_PROMPT);
      } catch (error) {
        const message =
          error instanceof Error ? error.message : "Unknown error";
        ctx.ui.notify(`Failed to start commit session: ${message}`, "error");
      }
    },
  });
}
