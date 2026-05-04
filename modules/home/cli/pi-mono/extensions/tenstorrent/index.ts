import {
  createAssistantMessageEventStream,
  parseJsonWithRepair,
  streamSimple,
  type AssistantMessage,
  type AssistantMessageEventStream,
  type Context,
  type Model,
  type SimpleStreamOptions,
  type TextContent,
  type ThinkingContent,
  type ToolCall,
} from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const TENSTORRENT_API = "tenstorrent-openai";
const OPENAI_COMPLETIONS_API = "openai-completions";

const TOOL_CALLS_BEGIN = "<｜tool▁calls▁begin｜>";
const TOOL_CALLS_END = "<｜tool▁calls▁end｜>";
const TOOL_CALL_BEGIN = "<｜tool▁call▁begin｜>function<｜tool▁sep｜>";
const TOOL_CALL_END = "<｜tool▁call▁end｜>";
const JSON_FENCE = "```json";
const FENCE = "```";

type ParsedContentBlock = TextContent | ThinkingContent | ToolCall;

function nonEmptyText(text: string): TextContent | undefined {
  const cleaned = text.replaceAll(TOOL_CALLS_BEGIN, "").replaceAll(TOOL_CALLS_END, "");
  return cleaned.trim().length > 0 ? { type: "text", text: cleaned } : undefined;
}

function parseToolCallArguments(rawJson: string): Record<string, unknown> {
  try {
    return parseJsonWithRepair<Record<string, unknown>>(rawJson.trim());
  } catch {
    return {};
  }
}

function parseTenstorrentText(text: string): ParsedContentBlock[] {
  const blocks: ParsedContentBlock[] = [];
  let cursor = 0;
  let callIndex = 0;

  while (cursor < text.length) {
    const callStart = text.indexOf(TOOL_CALL_BEGIN, cursor);
    if (callStart === -1) break;

    const before = nonEmptyText(text.slice(cursor, callStart));
    if (before) blocks.push(before);

    const nameStart = callStart + TOOL_CALL_BEGIN.length;
    const nameEnd = text.indexOf("\n", nameStart);
    if (nameEnd === -1) break;

    const toolName = text.slice(nameStart, nameEnd).trim();
    const jsonFenceStart = text.indexOf(JSON_FENCE, nameEnd);
    const callEnd = text.indexOf(TOOL_CALL_END, nameEnd);
    if (!toolName || jsonFenceStart === -1 || callEnd === -1) break;

    const jsonStart = jsonFenceStart + JSON_FENCE.length;
    const jsonEnd = text.indexOf(FENCE, jsonStart);
    if (jsonEnd === -1 || jsonEnd > callEnd) break;

    blocks.push({
      type: "toolCall",
      id: `tenstorrent_${Date.now()}_${callIndex++}`,
      name: toolName,
      arguments: parseToolCallArguments(text.slice(jsonStart, jsonEnd)),
    });

    cursor = callEnd + TOOL_CALL_END.length;
  }

  const after = nonEmptyText(text.slice(cursor));
  if (after) blocks.push(after);

  return blocks.length > 0 ? blocks : [{ type: "text", text }];
}

function normalizeTenstorrentContext(context: Context): Context {
  return {
    ...context,
    messages: context.messages.map((message) => {
      if (message.role !== "user" || typeof message.content === "string") return message;
      if (!message.content.every((block): block is TextContent => block.type === "text")) return message;
      return {
        ...message,
        content: message.content.map((block) => block.text).join("\n"),
      };
    }),
  };
}

function transformTenstorrentMessage(message: AssistantMessage, model: Model<string>): AssistantMessage {
  const content = message.content.flatMap((block): ParsedContentBlock[] => {
    if (block.type === "text") {
      return parseTenstorrentText(block.text);
    }
    return [block];
  });

  return {
    ...message,
    api: model.api,
    provider: model.provider,
    model: model.id,
    content,
    stopReason: content.some((block) => block.type === "toolCall") ? "toolUse" : message.stopReason,
  };
}

function emitContentBlocks(stream: AssistantMessageEventStream, output: AssistantMessage) {
  const content = output.content;
  output.content = [];

  for (const block of content) {
    const contentIndex = output.content.length;

    if (block.type === "thinking") {
      output.content.push({ ...block, thinking: "" });
      stream.push({ type: "thinking_start", contentIndex, partial: output });
      const outputBlock = output.content[contentIndex];
      if (outputBlock.type === "thinking") {
        outputBlock.thinking = block.thinking;
      }
      stream.push({ type: "thinking_delta", contentIndex, delta: block.thinking, partial: output });
      stream.push({ type: "thinking_end", contentIndex, content: block.thinking, partial: output });
      continue;
    }

    if (block.type === "toolCall") {
      output.content.push({ ...block, arguments: {} });
      stream.push({ type: "toolcall_start", contentIndex, partial: output });
      const json = JSON.stringify(block.arguments);
      const outputBlock = output.content[contentIndex];
      if (outputBlock.type === "toolCall") {
        outputBlock.arguments = block.arguments;
      }
      stream.push({ type: "toolcall_delta", contentIndex, delta: json, partial: output });
      stream.push({ type: "toolcall_end", contentIndex, toolCall: block, partial: output });
      continue;
    }

    output.content.push({ ...block, text: "" });
    stream.push({ type: "text_start", contentIndex, partial: output });
    const outputBlock = output.content[contentIndex];
    if (outputBlock.type === "text") {
      outputBlock.text = block.text;
    }
    stream.push({ type: "text_delta", contentIndex, delta: block.text, partial: output });
    stream.push({ type: "text_end", contentIndex, content: block.text, partial: output });
  }
}

function streamTenstorrent(
  model: Model<string>,
  context: Context,
  options?: SimpleStreamOptions,
): AssistantMessageEventStream {
  const stream = createAssistantMessageEventStream();

  void (async () => {
    const output: AssistantMessage = {
      role: "assistant",
      content: [],
      api: model.api,
      provider: model.provider,
      model: model.id,
      usage: {
        input: 0,
        output: 0,
        cacheRead: 0,
        cacheWrite: 0,
        totalTokens: 0,
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 },
      },
      stopReason: "stop",
      timestamp: Date.now(),
    };

    try {
      stream.push({ type: "start", partial: output });

      const upstreamModel = { ...model, api: OPENAI_COMPLETIONS_API };
      const upstream = streamSimple(upstreamModel, normalizeTenstorrentContext(context), options);
      const upstreamMessage = await upstream.result();
      const transformed = transformTenstorrentMessage(upstreamMessage, model);

      Object.assign(output, transformed);
      emitContentBlocks(stream, output);

      stream.push({
        type: "done",
        reason: output.stopReason as "stop" | "length" | "toolUse",
        message: output,
      });
      stream.end();
    } catch (error) {
      output.stopReason = options?.signal?.aborted ? "aborted" : "error";
      output.errorMessage = error instanceof Error ? error.message : String(error);
      stream.push({ type: "error", reason: output.stopReason, error: output });
      stream.end();
    }
  })();

  return stream;
}

export default function (pi: ExtensionAPI) {
  pi.registerProvider("tenstorrent-api", {
    api: TENSTORRENT_API,
    streamSimple: streamTenstorrent,
  });
}
