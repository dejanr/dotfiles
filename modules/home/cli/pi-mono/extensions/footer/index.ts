/**
 * Custom Footer Extension - shows working directory, git branch, model, context usage, and extension statuses
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setFooter((tui, theme, footerData) => {
			const unsub = footerData.onBranchChange(() => tui.requestRender());

			return {
				dispose: unsub,
				invalidate() {},
				render(width: number): string[] {
					const messages = ctx.sessionManager
						.getBranch()
						.filter(
							(e): e is { type: "message"; message: AssistantMessage } =>
								e.type === "message" && e.message.role === "assistant",
						)
						.map((e) => e.message)
						.filter((message) => message.stopReason !== "aborted");

					const lastMessage = messages[messages.length - 1];

					const contextTokens = lastMessage
						? lastMessage.usage.input +
							lastMessage.usage.output +
							lastMessage.usage.cacheRead +
							lastMessage.usage.cacheWrite
						: 0;

					const contextWindow = ctx.model?.contextWindow || 0;

					const fmt = (value: number) => {
						if (value < 1000) return value.toString();
						if (value < 10000) return `${(value / 1000).toFixed(1)}k`;
						if (value < 1000000) return `${Math.round(value / 1000)}k`;
						return `${(value / 1000000).toFixed(1)}M`;
					};

					const branch = footerData.getGitBranch();
					const branchStr = branch
						? `${theme.fg("dim", " │ ")}${theme.fg("success", " ")}${theme.fg("accent", branch)}`
						: "";

					const statuses = footerData.getExtensionStatuses();
					let statusStr = "";
					if (statuses.size > 0) {
						const statusParts: string[] = [];
						for (const [, value] of statuses) {
							if (value && value.trim()) {
								statusParts.push(value);
							}
						}
						if (statusParts.length > 0) {
							statusStr = `${theme.fg("dim", " │ ")}${statusParts.join(theme.fg("dim", " │ "))}`;
						}
					}

					const cwd = ctx.cwd;
					const home = process.env.HOME || "";
					const shortCwd = home && cwd.startsWith(home) ? `~${cwd.slice(home.length)}` : cwd;

					const left = `${theme.fg("muted", shortCwd)}${branchStr}${statusStr}`;

					const modelId = ctx.model?.id || "no-model";

					const percentValue = contextWindow > 0 ? (contextTokens / contextWindow) * 100 : 0;
					let contextColor: "success" | "warning" | "error";
					if (percentValue > 90) {
						contextColor = "error";
					} else if (percentValue > 70) {
						contextColor = "warning";
					} else {
						contextColor = "success";
					}

					const contextDisplay = `${theme.fg(contextColor, fmt(contextTokens))}${theme.fg("dim", "/")}${theme.fg("accent", fmt(contextWindow))}`;
					const right = `${contextDisplay}${theme.fg("dim", " │ ")}${theme.fg("toolTitle", modelId)}`;

					const pad = " ".repeat(
						Math.max(1, width - visibleWidth(left) - visibleWidth(right)),
					);
					return [truncateToWidth(`${left}${pad}${right}`, width)];
				},
			};
		});
	});
}
