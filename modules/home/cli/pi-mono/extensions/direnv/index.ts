/**
 * Direnv Extension
 *
 * Loads direnv environment variables on session start and after each bash
 * command. This mimics how the shell hook works - it runs after every command
 * to pick up any .envrc changes from cd, git checkout, etc.
 *
 * Requirements:
 *   - direnv installed and in PATH
 *   - .envrc must be allowed (run `direnv allow` in your shell first)
 */

import { execSync } from "node:child_process";
import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";

function loadDirenv(cwd: string, ctx: ExtensionContext) {
	try {
		// Check if direnv is active in this directory
		const status = execSync("direnv status --json", {
			cwd,
			encoding: "utf-8",
			stdio: ["pipe", "pipe", "pipe"],
		});
		const statusJson = JSON.parse(status) as { state?: { foundRC?: { path?: string } } };
		const hasEnvrc = !!statusJson.state?.foundRC?.path;

		if (!hasEnvrc) {
			// No .envrc in this directory, clear status
			if (ctx.hasUI) {
				ctx.ui.setStatus("direnv", "");
			}
			return;
		}

		// Load any environment changes
		const output = execSync("direnv export json", {
			cwd,
			encoding: "utf-8",
			stdio: ["pipe", "pipe", "pipe"],
		});

		if (output.trim()) {
			const env = JSON.parse(output) as Record<string, string | null>;
			for (const [key, value] of Object.entries(env)) {
				if (value === null) {
					delete process.env[key];
				} else {
					process.env[key] = value;
				}
			}
		}

		// Show status when .envrc exists
		if (ctx.hasUI) {
			ctx.ui.setStatus("direnv", ctx.ui.theme.fg("success", "direnv ✓"));
		}
	} catch {
		if (ctx.hasUI) {
			ctx.ui.setStatus("direnv", ctx.ui.theme.fg("error", "direnv ✗"));
		}
	}
}

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		loadDirenv(ctx.cwd, ctx);
	});

	pi.on("tool_result", (event, ctx) => {
		if (event.toolName !== "bash") return;
		loadDirenv(ctx.cwd, ctx);
	});
}
