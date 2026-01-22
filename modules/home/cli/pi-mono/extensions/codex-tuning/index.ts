import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { DEFAULT_MAX_BYTES, DEFAULT_MAX_LINES, formatSize, truncateHead } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { constants, existsSync } from "fs";
import { access, mkdir, readFile, unlink, writeFile } from "fs/promises";
import { tmpdir } from "os";
import { dirname, resolve } from "path";
import { randomBytes } from "crypto";

const applyPatchSchema = Type.Object({
	input: Type.String({
		description: "The entire contents of the apply_patch command",
	}),
});

const shellSchema = Type.Object({
	command: Type.Array(Type.String({ description: "Command arguments" })),
	workdir: Type.Optional(Type.String({ description: "Working directory for the command" })),
	timeout_ms: Type.Optional(Type.Number({ description: "Timeout in milliseconds" })),
	sandbox_permissions: Type.Optional(
		Type.String({ description: "Sandbox permissions (ignored in pi extension)" }),
	),
	justification: Type.Optional(Type.String({ description: "Escalation justification (ignored in pi extension)" })),
});

const shellCommandSchema = Type.Object({
	command: Type.String({ description: "Shell script to execute" }),
	workdir: Type.Optional(Type.String({ description: "Working directory for the command" })),
	login: Type.Optional(Type.Boolean({ description: "Run shell with login semantics" })),
	timeout_ms: Type.Optional(Type.Number({ description: "Timeout in milliseconds" })),
	sandbox_permissions: Type.Optional(
		Type.String({ description: "Sandbox permissions (ignored in pi extension)" }),
	),
	justification: Type.Optional(Type.String({ description: "Escalation justification (ignored in pi extension)" })),
});

type PatchHunk =
	| { type: "add"; path: string; lines: string[] }
	| { type: "delete"; path: string }
	| { type: "update"; path: string; newPath?: string; lines: string[]; endOfFile: boolean };

type AppliedChange = {
	path: string;
	action: "add" | "delete" | "update" | "move";
	message: string;
};

function normalizeNewlines(value: string): string {
	return value.replace(/\r\n/g, "\n").replace(/\r/g, "\n");
}

function detectLineEnding(content: string): "\r\n" | "\n" {
	return content.includes("\r\n") ? "\r\n" : "\n";
}

function stripBom(content: string): { bom: string; text: string } {
	return content.startsWith("\uFEFF") ? { bom: "\uFEFF", text: content.slice(1) } : { bom: "", text: content };
}

function restoreLineEndings(text: string, ending: "\r\n" | "\n"): string {
	return ending === "\r\n" ? text.replace(/\n/g, "\r\n") : text;
}

function buildShellCommand(command: string, login?: boolean): string[] {
	if (process.platform === "win32") {
		return ["powershell.exe", "-Command", command];
	}

	const envShell = process.env.SHELL;
	if (envShell && existsSync(envShell)) {
		return login === false ? [envShell, "-c", command] : [envShell, "-lc", command];
	}

	if (existsSync("/bin/bash")) {
		return login === false ? ["/bin/bash", "-c", command] : ["/bin/bash", "-lc", command];
	}

	return ["sh", "-c", command];
}

function parsePatch(input: string): PatchHunk[] {
	const normalized = normalizeNewlines(input);
	const startIndex = normalized.indexOf("*** Begin Patch");
	if (startIndex === -1) {
		throw new Error("Patch must include '*** Begin Patch' header.");
	}

	const payload = normalized.slice(startIndex);
	const rawLines = payload.split("\n");
	if (rawLines[rawLines.length - 1] === "") {
		rawLines.pop();
	}

	if (rawLines[0] !== "*** Begin Patch") {
		throw new Error("Patch must start with '*** Begin Patch'.");
	}

	const hunks: PatchHunk[] = [];
	let index = 1;

	const isHunkStart = (line: string) =>
		line.startsWith("*** Add File: ") ||
		line.startsWith("*** Delete File: ") ||
		line.startsWith("*** Update File: ");

	while (index < rawLines.length) {
		const line = rawLines[index];

		if (line === "*** End Patch") {
			return hunks;
		}

		if (line.startsWith("*** Add File: ")) {
			const path = line.slice("*** Add File: ".length).trim();
			const lines: string[] = [];
			index += 1;
			while (index < rawLines.length && !isHunkStart(rawLines[index]) && rawLines[index] !== "*** End Patch") {
				const addLine = rawLines[index];
				if (!addLine.startsWith("+")) {
					throw new Error(`Invalid add line '${addLine}'. Add file hunks must use '+' prefixes.`);
				}
				lines.push(addLine.slice(1));
				index += 1;
			}
			if (lines.length === 0) {
				throw new Error(`Add file hunk for '${path}' has no content.`);
			}
			hunks.push({ type: "add", path, lines });
			continue;
		}

		if (line.startsWith("*** Delete File: ")) {
			const path = line.slice("*** Delete File: ".length).trim();
			hunks.push({ type: "delete", path });
			index += 1;
			continue;
		}

		if (line.startsWith("*** Update File: ")) {
			const path = line.slice("*** Update File: ".length).trim();
			let newPath: string | undefined;
			const lines: string[] = [];
			let endOfFile = false;
			index += 1;

			if (rawLines[index]?.startsWith("*** Move to: ")) {
				newPath = rawLines[index].slice("*** Move to: ".length).trim();
				index += 1;
			}

			while (index < rawLines.length && !isHunkStart(rawLines[index]) && rawLines[index] !== "*** End Patch") {
				const changeLine = rawLines[index];
				if (changeLine === "*** End of File") {
					endOfFile = true;
					index += 1;
					break;
				}
				if (!changeLine.startsWith("@@") && !changeLine.startsWith("+") && !changeLine.startsWith("-") && !changeLine.startsWith(" ")) {
					throw new Error(`Invalid patch line '${changeLine}'. Lines must start with ' ', '+', '-', or '@@'.`);
				}
				lines.push(changeLine);
				index += 1;
			}

			if (lines.length === 0 && !newPath) {
				throw new Error(`Update hunk for '${path}' has no changes.`);
			}

			hunks.push({ type: "update", path, newPath, lines, endOfFile });
			continue;
		}

		throw new Error(`Unexpected patch line '${line}'.`);
	}

	throw new Error("Patch must end with '*** End Patch'.");
}

function splitIntoChunks(lines: string[]): string[][] {
	const chunks: string[][] = [];
	let current: string[] = [];

	for (const line of lines) {
		if (line.startsWith("@@")) {
			if (current.length > 0) {
				chunks.push(current);
				current = [];
			}
			continue;
		}
		current.push(line);
	}

	if (current.length > 0) {
		chunks.push(current);
	}

	return chunks;
}

function findPatternStart(originalLines: string[], start: number, pattern: string[]): number {
	if (pattern.length === 0) {
		return start;
	}

	for (let i = start; i <= originalLines.length - pattern.length; i++) {
		let matches = true;
		for (let j = 0; j < pattern.length; j++) {
			if (originalLines[i + j] !== pattern[j]) {
				matches = false;
				break;
			}
		}
		if (matches) {
			return i;
		}
	}

	return -1;
}

function applyUpdatePatch(originalLines: string[], patchLines: string[]): string[] {
	let cursor = 0;
	const output: string[] = [];
	const chunks = splitIntoChunks(patchLines);

	for (const chunk of chunks) {
		const matchLines = chunk
			.filter((line) => line.startsWith(" ") || line.startsWith("-"))
			.map((line) => line.slice(1));
		const matchIndex = findPatternStart(originalLines, cursor, matchLines);
		if (matchIndex === -1) {
			throw new Error("Failed to locate patch context in target file.");
		}

		output.push(...originalLines.slice(cursor, matchIndex));
		let localIndex = matchIndex;

		for (const line of chunk) {
			if (line === "") {
				throw new Error("Patch line missing prefix. Every line must start with ' ', '+', or '-'.");
			}
			const prefix = line[0];
			const text = line.slice(1);

			switch (prefix) {
				case " ": {
					if (originalLines[localIndex] !== text) {
						throw new Error(`Context mismatch: expected '${text}', found '${originalLines[localIndex] ?? ""}'.`);
					}
					output.push(originalLines[localIndex]);
					localIndex += 1;
					break;
				}
				case "-": {
					if (originalLines[localIndex] !== text) {
						throw new Error(`Delete mismatch: expected '${text}', found '${originalLines[localIndex] ?? ""}'.`);
					}
					localIndex += 1;
					break;
				}
				case "+": {
					output.push(text);
					break;
				}
				default:
					throw new Error(`Invalid patch line '${line}'. Every line must start with ' ', '+', or '-'.`);
			}
		}

		cursor = localIndex;
	}

	output.push(...originalLines.slice(cursor));
	return output;
}

async function applyPatchHunk(hunk: PatchHunk, cwd: string): Promise<AppliedChange[]> {
	switch (hunk.type) {
		case "add": {
			const targetPath = resolve(cwd, hunk.path);
			try {
				await access(targetPath, constants.F_OK);
				throw new Error(`File already exists: ${hunk.path}`);
			} catch (error: any) {
				if (error?.code && error.code !== "ENOENT") {
					throw error;
				}
			}

			await mkdir(dirname(targetPath), { recursive: true });
			const content = hunk.lines.join("\n");
			await writeFile(targetPath, content, "utf-8");
			return [{ path: hunk.path, action: "add", message: "File added" }];
		}
		case "delete": {
			const targetPath = resolve(cwd, hunk.path);
			await access(targetPath, constants.F_OK);
			await unlink(targetPath);
			return [{ path: hunk.path, action: "delete", message: "File deleted" }];
		}
		case "update": {
			const sourcePath = resolve(cwd, hunk.path);
			await access(sourcePath, constants.F_OK);
			const rawContent = await readFile(sourcePath, "utf-8");
			const { bom, text } = stripBom(rawContent);
			const lineEnding = detectLineEnding(rawContent);
			const normalizedText = normalizeNewlines(text);
			const originalLines = normalizedText.split("\n");
			const targetPath = hunk.newPath ? resolve(cwd, hunk.newPath) : sourcePath;

			let updatedText = bom + restoreLineEndings(normalizedText, lineEnding);
			if (hunk.lines.length > 0) {
				let patchedLines = applyUpdatePatch(originalLines, hunk.lines);
				if (hunk.endOfFile && patchedLines.length > 0 && patchedLines[patchedLines.length - 1] === "") {
					patchedLines = patchedLines.slice(0, -1);
				}
				updatedText = bom + restoreLineEndings(patchedLines.join("\n"), lineEnding);
			}

			await mkdir(dirname(targetPath), { recursive: true });
			await writeFile(targetPath, updatedText, "utf-8");

			const changes: AppliedChange[] = [{ path: hunk.path, action: "update", message: "File updated" }];
			if (hunk.newPath && targetPath !== sourcePath) {
				await unlink(sourcePath);
				changes.push({ path: hunk.newPath, action: "move", message: "File moved" });
			}
			return changes;
		}
	}
}

function isCodexModel(model: { id?: string; provider?: string } | string | undefined): boolean {
	if (!model) return false;
	if (typeof model === "string") {
		return model.toLowerCase().includes("codex");
	}
	const providerMatch = model.provider?.toLowerCase().includes("codex") ?? false;
	const idMatch = model.id?.toLowerCase().includes("codex") ?? false;
	return providerMatch || idMatch;
}

function formatChanges(changes: AppliedChange[]): string {
	const lines = changes.map((change) => `- ${change.action.toUpperCase()}: ${change.path} (${change.message})`);
	return ["apply_patch results:", ...lines].join("\n");
}

function middleTruncateByBytes(content: string, maxBytes: number): { text: string; truncated: boolean } {
	const totalBytes = Buffer.byteLength(content, "utf-8");
	if (totalBytes <= maxBytes) {
		return { text: content, truncated: false };
	}
	if (maxBytes === 0) {
		return { text: "…content truncated…", truncated: true };
	}

	const leftBudget = Math.floor(maxBytes / 2);
	const rightBudget = maxBytes - leftBudget;
	const totalChars = Array.from(content).length;
	let prefixEnd = 0;
	let suffixStart = content.length;
	let prefixChars = 0;
	let suffixChars = 0;
	let byteOffset = 0;
	let suffixStarted = false;

	for (let i = 0; i < content.length; ) {
		const codePoint = content.codePointAt(i);
		if (codePoint === undefined) {
			break;
		}
		const char = String.fromCodePoint(codePoint);
		const charBytes = Buffer.byteLength(char, "utf-8");
		const charLength = char.length;

		if (byteOffset + charBytes <= leftBudget) {
			prefixEnd = i + charLength;
			prefixChars += 1;
		}

		if (byteOffset >= totalBytes - rightBudget) {
			if (!suffixStarted) {
				suffixStart = i;
				suffixStarted = true;
			}
			suffixChars += 1;
		}

		byteOffset += charBytes;
		i += charLength;
	}

	if (suffixStart < prefixEnd) {
		suffixStart = prefixEnd;
	}

	const removedChars = Math.max(0, totalChars - prefixChars - suffixChars);
	const marker = `…${removedChars} chars truncated…`;
	const truncated = content.slice(0, prefixEnd) + marker + content.slice(suffixStart);
	return { text: truncated, truncated: true };
}

function formatShellOutput(result: {
	output: string;
	exitCode: number;
	durationMs: number;
	timedOut: boolean;
}): string {
	const wallTimeSeconds = (result.durationMs / 1000).toFixed(1);
	let content = result.output;
	if (result.timedOut) {
		content = `command timed out after ${result.durationMs} milliseconds\n${content}`.trim();
	}

	const totalLines = content.length === 0 ? 0 : content.split("\n").length;
	const truncated = middleTruncateByBytes(content, DEFAULT_MAX_BYTES);
	const truncatedLines = truncated.text.length === 0 ? 0 : truncated.text.split("\n").length;

	const sections = [
		`Exit code: ${result.exitCode}`,
		`Wall time: ${wallTimeSeconds} seconds`,
	];

	if (totalLines !== truncatedLines) {
		sections.push(`Total output lines: ${totalLines}`);
	}

	sections.push("Output:");
	sections.push(truncated.text);

	return sections.join("\n");
}

async function truncateOutput(output: string): Promise<string> {
	const truncation = truncateHead(output, {
		maxBytes: DEFAULT_MAX_BYTES,
		maxLines: DEFAULT_MAX_LINES,
	});

	if (!truncation.truncated) {
		return truncation.content;
	}

	const tempPath = resolve(
		tmpdir(),
		`pi-apply-patch-${Date.now()}-${randomBytes(4).toString("hex")}.log`,
	);
	await writeFile(tempPath, output, "utf-8");

	return (
		truncation.content +
		`\n\n[Output truncated: ${truncation.outputLines} of ${truncation.totalLines} lines ` +
		`(${formatSize(truncation.outputBytes)} of ${formatSize(truncation.totalBytes)}). ` +
		`Full output saved to: ${tempPath}]`
	);
}

async function executeApplyPatch(
	patchInput: string,
	ctx: { cwd: string },
	signal?: AbortSignal,
): Promise<{ content: Array<{ type: "text"; text: string }>; details: { changes: AppliedChange[] } }> {
	if (signal?.aborted) {
		return {
			content: [{ type: "text", text: "apply_patch cancelled." }],
			details: { changes: [] },
		};
	}

	const hunks = parsePatch(patchInput);
	const applied: AppliedChange[] = [];

	for (const hunk of hunks) {
		if (signal?.aborted) {
			throw new Error("Operation aborted");
		}
		const results = await applyPatchHunk(hunk, ctx.cwd);
		applied.push(...results);
	}

	const output = await truncateOutput(formatChanges(applied));
	return {
		content: [{ type: "text", text: output }],
		details: { changes: applied },
	};
}

export default function (pi: ExtensionAPI) {
	let applyPatchToolRegistered = false;
	let shellToolRegistered = false;

	const registerApplyPatchTool = () => {
		if (applyPatchToolRegistered) return;
		applyPatchToolRegistered = true;

		pi.registerTool({
			name: "apply_patch",
			label: "apply_patch",
			description:
				"Apply a patch in Codex format. Provide the full patch starting with '*** Begin Patch' and ending with '*** End Patch'.",
			parameters: applyPatchSchema,
			async execute(_toolCallId, params, _onUpdate, ctx, signal) {
				return executeApplyPatch(params.input, ctx, signal);
			},
		});
	};

	const registerShellTool = () => {
		if (shellToolRegistered) return;
		shellToolRegistered = true;

		const executeShellArgs = async (
			command: string[],
			params: { workdir?: string; timeout_ms?: number },
			ctx: { cwd: string },
			signal?: AbortSignal,
			allowApplyPatch = false,
		) => {
			if (!command || command.length === 0) {
				throw new Error("shell command must include at least one argument");
			}

			if (allowApplyPatch && command[0] === "apply_patch") {
				const patchInput = command.length === 2 ? command[1] : command.slice(1).join(" ");
				return executeApplyPatch(patchInput, ctx, signal);
			}

			const resolvedCwd = params.workdir ? resolve(ctx.cwd, params.workdir) : ctx.cwd;
			const start = Date.now();
			const result = await pi.exec(command[0], command.slice(1), {
				cwd: resolvedCwd,
				timeout: params.timeout_ms,
				signal,
			});

			const durationMs = Date.now() - start;
			const timedOut = Boolean(params.timeout_ms && result.killed && !signal?.aborted);
			const combinedOutput = `${result.stdout}${result.stderr}`.trimEnd();
			const formatted = formatShellOutput({
				output: combinedOutput,
				exitCode: result.code,
				durationMs,
				timedOut,
			});

			return {
				content: [{ type: "text", text: formatted }],
				details: { exitCode: result.code, cwd: resolvedCwd, timedOut },
			};
		};

		const registerShellVariant = (
			name: string,
			label: string,
			description: string,
			schema: typeof shellSchema,
		) => {
			pi.registerTool({
				name,
				label,
				description,
				parameters: schema,
				async execute(_toolCallId, params, _onUpdate, ctx, signal) {
					return executeShellArgs(params.command, params, ctx, signal, true);
				},
			});
		};

		registerShellVariant(
			"shell",
			"shell",
			"Runs a shell command and returns its output. Provide the command as an argument array; prefer ['bash', '-lc', '...'] for POSIX shells.",
			shellSchema,
		);
		registerShellVariant(
			"local_shell",
			"local_shell",
			"Runs a local shell command and returns its output.",
			shellSchema,
		);
		pi.registerTool({
			name: "shell_command",
			label: "shell_command",
			description:
				"Runs a shell script and returns its output. Provide the script as a single string.",
			parameters: shellCommandSchema,
			async execute(_toolCallId, params, _onUpdate, ctx, signal) {
				const commandArgs = buildShellCommand(params.command, params.login);
				return executeShellArgs(commandArgs, params, ctx, signal, false);
			},
		});
	};

	const updateActiveTools = (model?: { id?: string; provider?: string }) => {
		const activeTools = new Set(pi.getActiveTools());
		const shouldEnable = isCodexModel(model);
		let changed = false;

		if (shouldEnable) {
			const exposedTools = ["apply_patch", "shell"];
			for (const tool of exposedTools) {
				if (!activeTools.has(tool)) {
					activeTools.add(tool);
					changed = true;
				}
			}
		} else {
			const codexTools = ["apply_patch", "shell", "shell_command", "local_shell"];
			for (const tool of codexTools) {
				if (activeTools.delete(tool)) {
					changed = true;
				}
			}
		}

		if (changed) {
			pi.setActiveTools(Array.from(activeTools));
		}
	};

	registerApplyPatchTool();
	registerShellTool();

	pi.on("session_start", (_event, ctx) => {
		updateActiveTools(ctx.model);
	});

	pi.on("model_select", (event) => {
		updateActiveTools(event.model);
	});
}
