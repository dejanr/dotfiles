import { execSync } from "node:child_process";
import { existsSync, statSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI, ExtensionContext, SessionEntry } from "@mariozechner/pi-coding-agent";
import { DynamicBorder } from "@mariozechner/pi-coding-agent";
import {
	Container,
	type SelectItem,
	SelectList,
	Text,
	Input,
	Spacer,
	fuzzyFilter,
	getEditorKeybindings,
} from "@mariozechner/pi-tui";

type ContentBlock = {
	type?: string;
	text?: string;
	arguments?: Record<string, unknown>;
};

type FileReference = {
	path: string;
	display: string;
	exists: boolean;
	isDirectory: boolean;
};

const FILE_TAG_REGEX = /<file\s+name=["']([^"']+)["']>/g;
const FILE_URL_REGEX = /file:\/\/[^\s"'<>]+/g;
const PATH_REGEX = /(?:^|[\s"'`([{<])((?:~|\/)[^\s"'`<>)}\]]+)/g;

const extractFileReferencesFromText = (text: string): string[] => {
	const refs: string[] = [];

	for (const match of text.matchAll(FILE_TAG_REGEX)) {
		refs.push(match[1]);
	}

	for (const match of text.matchAll(FILE_URL_REGEX)) {
		refs.push(match[0]);
	}

	for (const match of text.matchAll(PATH_REGEX)) {
		refs.push(match[1]);
	}

	return refs;
};

const extractPathsFromToolArgs = (args: unknown): string[] => {
	if (!args || typeof args !== "object") {
		return [];
	}

	const refs: string[] = [];
	const record = args as Record<string, unknown>;
	const directKeys = ["path", "file", "filePath", "filepath", "fileName", "filename"] as const;
	const listKeys = ["paths", "files", "filePaths"] as const;

	for (const key of directKeys) {
		const value = record[key];
		if (typeof value === "string") {
			refs.push(value);
		}
	}

	for (const key of listKeys) {
		const value = record[key];
		if (Array.isArray(value)) {
			for (const item of value) {
				if (typeof item === "string") {
					refs.push(item);
				}
			}
		}
	}

	return refs;
};

const extractFileReferencesFromContent = (content: unknown): string[] => {
	if (typeof content === "string") {
		return extractFileReferencesFromText(content);
	}

	if (!Array.isArray(content)) {
		return [];
	}

	const refs: string[] = [];
	for (const part of content) {
		if (!part || typeof part !== "object") {
			continue;
		}

		const block = part as ContentBlock;

		if (block.type === "text" && typeof block.text === "string") {
			refs.push(...extractFileReferencesFromText(block.text));
		}

		if (block.type === "toolCall") {
			refs.push(...extractPathsFromToolArgs(block.arguments));
		}
	}

	return refs;
};

const extractFileReferencesFromEntry = (entry: SessionEntry): string[] => {
	if (entry.type === "message") {
		const message = entry.message as { content?: unknown };
		if ("content" in message && message.content) {
			return extractFileReferencesFromContent(message.content);
		}
		return [];
	}

	if (entry.type === "custom_message") {
		return extractFileReferencesFromContent(entry.content);
	}

	return [];
};

const sanitizeReference = (raw: string): string => {
	let value = raw.trim();
	value = value.replace(/^["'`(<\[]+/, "");
	value = value.replace(/[>"'`,;).\]]+$/, "");
	value = value.replace(/[.,;:]+$/, "");
	return value;
};

const isCommentLikeReference = (value: string): boolean => value.startsWith("//");

const stripLineSuffix = (value: string): string => {
	let result = value.replace(/#L\d+(C\d+)?$/i, "");
	const lastSeparator = Math.max(result.lastIndexOf("/"), result.lastIndexOf("\\"));
	const segmentStart = lastSeparator >= 0 ? lastSeparator + 1 : 0;
	const segment = result.slice(segmentStart);
	const colonIndex = segment.indexOf(":");
	if (colonIndex >= 0 && /\d/.test(segment[colonIndex + 1] ?? "")) {
		result = result.slice(0, segmentStart + colonIndex);
		return result;
	}

	const lastColon = result.lastIndexOf(":");
	if (lastColon > lastSeparator) {
		const suffix = result.slice(lastColon + 1);
		if (/^\d+(?::\d+)?$/.test(suffix)) {
			result = result.slice(0, lastColon);
		}
	}
	return result;
};

const normalizeReferencePath = (raw: string, cwd: string): string | null => {
	let candidate = sanitizeReference(raw);
	if (!candidate || isCommentLikeReference(candidate)) {
		return null;
	}

	if (candidate.startsWith("file://")) {
		try {
			candidate = fileURLToPath(candidate);
		} catch {
			return null;
		}
	}

	candidate = stripLineSuffix(candidate);
	if (!candidate || isCommentLikeReference(candidate)) {
		return null;
	}

	if (candidate.startsWith("~")) {
		candidate = path.join(os.homedir(), candidate.slice(1));
	}

	if (!path.isAbsolute(candidate)) {
		candidate = path.resolve(cwd, candidate);
	}

	candidate = path.normalize(candidate);
	const root = path.parse(candidate).root;
	if (candidate.length > root.length) {
		candidate = candidate.replace(/[\\/]+$/, "");
	}

	return candidate;
};

const formatDisplayPath = (absolutePath: string, cwd: string): string => {
	const normalizedCwd = path.resolve(cwd);
	if (absolutePath.startsWith(normalizedCwd + path.sep)) {
		return path.relative(normalizedCwd, absolutePath);
	}
	return absolutePath;
};

const collectRecentFileReferences = (entries: SessionEntry[], cwd: string, limit: number): FileReference[] => {
	const results: FileReference[] = [];
	const seen = new Set<string>();

	for (let i = entries.length - 1; i >= 0 && results.length < limit; i -= 1) {
		const refs = extractFileReferencesFromEntry(entries[i]);
		for (let j = refs.length - 1; j >= 0 && results.length < limit; j -= 1) {
			const normalized = normalizeReferencePath(refs[j], cwd);
			if (!normalized || seen.has(normalized)) {
				continue;
			}

			seen.add(normalized);

			let exists = false;
			let isDirectory = false;
			if (existsSync(normalized)) {
				exists = true;
				const stats = statSync(normalized);
				isDirectory = stats.isDirectory();
			}

			results.push({
				path: normalized,
				display: formatDisplayPath(normalized, cwd),
				exists,
				isDirectory,
			});
		}
	}

	return results;
};

const findLatestFileReference = (entries: SessionEntry[], cwd: string): FileReference | null => {
	const refs = collectRecentFileReferences(entries, cwd, 100);
	return refs.find((ref) => ref.exists) ?? null;
};

const showFileSelector = async (
	ctx: ExtensionContext,
	items: FileReference[],
	selectedPath?: string | null,
): Promise<FileReference | null> => {
	const seenPaths = new Set<string>();
	const uniqueItems = items.filter((item) => {
		if (seenPaths.has(item.path)) {
			return false;
		}
		seenPaths.add(item.path);
		return true;
	});
	const orderedItems = uniqueItems.filter((item) => item.exists);

	const selectItems: SelectItem[] = orderedItems.map((item) => {
		const status = item.isDirectory ? " [directory]" : "";
		return {
			value: item.path,
			label: `${item.display}${status}`,
			description: "",
		};
	});

	return ctx.ui.custom<FileReference | null>((tui, theme, _kb, done) => {
		const container = new Container();
		container.addChild(new DynamicBorder((str) => theme.fg("accent", str)));
		container.addChild(new Text(theme.fg("accent", theme.bold("Select a file"))));

		const searchInput = new Input();
		container.addChild(searchInput);
		container.addChild(new Spacer(1));

		const listContainer = new Container();
		container.addChild(listContainer);
		container.addChild(new Text(theme.fg("dim", "Type to filter • enter to select • esc to cancel")));
		container.addChild(new DynamicBorder((str) => theme.fg("accent", str)));

		let filteredItems = selectItems;
		let selectList: SelectList | null = null;

		const updateList = () => {
			listContainer.clear();

			if (filteredItems.length === 0) {
				listContainer.addChild(new Text(theme.fg("warning", "  No matching files"), 0, 0));
				selectList = null;
				return;
			}

			selectList = new SelectList(filteredItems, Math.min(filteredItems.length, 12), {
				selectedPrefix: (text) => theme.fg("accent", text),
				selectedText: (text) => theme.fg("accent", text),
				description: (text) => theme.fg("muted", text),
				scrollInfo: (text) => theme.fg("dim", text),
				noMatch: (text) => theme.fg("warning", text),
			});

			if (selectedPath) {
				const index = filteredItems.findIndex((item) => item.value === selectedPath);
				if (index >= 0) {
					selectList.setSelectedIndex(index);
				}
			}

			selectList.onSelect = (item) => {
				const selected = orderedItems.find((entry) => entry.path === item.value);
				done(selected ?? null);
			};
			selectList.onCancel = () => done(null);

			listContainer.addChild(selectList);
		};

		const applyFilter = () => {
			const query = searchInput.getValue();
			filteredItems = query
				? fuzzyFilter(selectItems, query, (item) => `${item.label} ${item.value} ${item.description ?? ""}`)
				: selectItems;
			updateList();
		};

		applyFilter();

		return {
			render(width: number) {
				return container.render(width);
			},
			invalidate() {
				container.invalidate();
			},
			handleInput(data: string) {
				const kb = getEditorKeybindings();
				if (
					kb.matches(data, "selectUp") ||
					kb.matches(data, "selectDown") ||
					kb.matches(data, "selectConfirm") ||
					kb.matches(data, "selectCancel")
				) {
					if (selectList) {
						selectList.handleInput(data);
					} else if (kb.matches(data, "selectCancel")) {
						done(null);
					}
					tui.requestRender();
					return;
				}

				searchInput.handleInput(data);
				applyFilter();
				tui.requestRender();
			},
		};
	});
};

const canEditFile = (target: FileReference): boolean => {
	if (!existsSync(target.path)) {
		return false;
	}
	const stats = statSync(target.path);
	return !stats.isDirectory();
};

const showActionSelector = async (
	ctx: ExtensionContext,
	options: { canEdit: boolean; hasTmuxEditor: boolean },
): Promise<"edit" | "addToPrompt" | null> => {
	const actions: SelectItem[] = [
		...(options.canEdit && options.hasTmuxEditor ? [{ value: "edit", label: "Open in nvim" }] : []),
		{ value: "addToPrompt", label: "Add to prompt" },
	];

	return ctx.ui.custom<"edit" | "addToPrompt" | null>((tui, theme, _kb, done) => {
		const container = new Container();
		container.addChild(new DynamicBorder((str) => theme.fg("accent", str)));
		container.addChild(new Text(theme.fg("accent", theme.bold("Choose action"))));

		const selectList = new SelectList(actions, actions.length, {
			selectedPrefix: (text) => theme.fg("accent", text),
			selectedText: (text) => theme.fg("accent", text),
			description: (text) => theme.fg("muted", text),
			scrollInfo: (text) => theme.fg("dim", text),
			noMatch: (text) => theme.fg("warning", text),
		});

		selectList.onSelect = (item) =>
			done(item.value as "edit" | "addToPrompt");
		selectList.onCancel = () => done(null);

		container.addChild(selectList);
		container.addChild(new Text(theme.fg("dim", "Press enter to confirm or esc to cancel")));
		container.addChild(new DynamicBorder((str) => theme.fg("accent", str)));

		return {
			render(width: number) {
				return container.render(width);
			},
			invalidate() {
				container.invalidate();
			},
			handleInput(data: string) {
				selectList.handleInput(data);
				tui.requestRender();
			},
		};
	});
};

type TmuxEditorTarget = {
	session: string;
	window: string;
	pane?: string;
};

const findTmuxEditorWindow = (): TmuxEditorTarget | null => {
	try {
		const windows = execSync("tmux list-windows -a -F '#{session_name}:#{window_name}'", {
			encoding: "utf8",
			timeout: 5000,
		}).trim();

		for (const line of windows.split("\n")) {
			const [session, window] = line.split(":");
			if (window === "editor" || window === "nvim" || window === "vim") {
				return { session, window };
			}
		}

		return null;
	} catch {
		return null;
	}
};

const openInTmuxNvim = (
	ctx: ExtensionContext,
	target: FileReference,
	tmuxTarget: TmuxEditorTarget,
): void => {
	const paneTarget = `${tmuxTarget.session}:${tmuxTarget.window}`;

	try {
		const escapedPath = target.path.replace(/'/g, "'\\''");
		execSync(`tmux send-keys -t '${paneTarget}' Escape`, { timeout: 2000 });
		execSync(`tmux send-keys -t '${paneTarget}' ':e ${escapedPath}' Enter`, { timeout: 2000 });
		execSync(`tmux select-window -t '${paneTarget}'`, { timeout: 2000 });

		ctx.ui.notify(`Opened ${target.display} in nvim`, "info");
	} catch (error) {
		ctx.ui.notify(`Failed to open in nvim: ${error}`, "error");
	}
};

const addFileToPrompt = (ctx: ExtensionContext, target: FileReference): void => {
	const mentionTarget = target.display || target.path;
	const mention = `@${mentionTarget}`;
	const current = ctx.ui.getEditorText();
	const separator = current && !current.endsWith(" ") ? " " : "";
	ctx.ui.setEditorText(`${current}${separator}${mention}`);
	ctx.ui.notify(`Added ${mention} to prompt`, "info");
};

const runFileBrowser = async (pi: ExtensionAPI, ctx: ExtensionContext): Promise<void> => {
	if (!ctx.hasUI) {
		ctx.ui.notify("Reveal requires interactive mode", "error");
		return;
	}

	const entries = ctx.sessionManager.getBranch();
	const references = collectRecentFileReferences(entries, ctx.cwd, 100);

	if (references.length === 0) {
		ctx.ui.notify("No file reference found in the session", "warning");
		return;
	}

	let lastSelectedPath: string | null = null;
	while (true) {
		const selection = await showFileSelector(ctx, references, lastSelectedPath);
		if (!selection) {
			ctx.ui.notify("Reveal cancelled", "info");
			return;
		}

		lastSelectedPath = selection.path;

		if (!selection.exists) {
			ctx.ui.notify(`File not found: ${selection.path}`, "error");
			return;
		}

		const canEdit = canEditFile(selection);
		const tmuxTarget = findTmuxEditorWindow();

		const action = await showActionSelector(ctx, {
			canEdit,
			hasTmuxEditor: tmuxTarget !== null,
		});
		if (!action) {
			continue;
		}

		switch (action) {
			case "edit":
				if (!tmuxTarget) {
					ctx.ui.notify("No tmux editor window found", "warning");
					return;
				}
				openInTmuxNvim(ctx, selection, tmuxTarget);
				return;
			case "addToPrompt":
				addFileToPrompt(ctx, selection);
				return;
		}
	}
};

export default function (pi: ExtensionAPI): void {
	pi.registerCommand("files", {
		description: "Reveal, open, or edit files mentioned in the conversation",
		handler: async (_args, ctx) => {
			await runFileBrowser(pi, ctx);
		},
	});

	pi.registerShortcut("ctrl+f", {
		description: "Browse files mentioned in the session",
		handler: async (ctx) => {
			await runFileBrowser(pi, ctx);
		},
	});

	pi.registerShortcut("alt+r", {
		description: "Open the latest file reference in nvim",
		handler: async (ctx) => {
			const entries = ctx.sessionManager.getBranch();
			const latest = findLatestFileReference(entries, ctx.cwd);

			if (!latest) {
				if (ctx.hasUI) {
					ctx.ui.notify("No file reference found in the session", "warning");
				}
				return;
			}

			const tmuxTarget = findTmuxEditorWindow();
			if (!tmuxTarget) {
				ctx.ui.notify("No tmux editor window found", "warning");
				return;
			}

			openInTmuxNvim(ctx, latest, tmuxTarget);
		},
	});
}