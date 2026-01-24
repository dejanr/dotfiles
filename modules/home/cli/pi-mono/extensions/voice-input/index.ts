/**
 * Voice Input Extension
 *
 * Press Ctrl+R to record audio, which is transcribed via ElevenLabs
 * in real-time and sent as a user message to the agent.
 *
 * Requires:
 * - ELEVENLABS_API_KEY in env
 * - sox installed: `brew install sox` (macOS) or `apt install sox` (Linux)
 *
 * Optional:
 * - ELEVENLABS_LANGUAGE - ISO-639-1/3 language code (e.g., "en", "ru", "de")
 */

import {
  CustomEditor,
  type ExtensionAPI,
  type KeybindingsManager,
  type Theme,
} from "@mariozechner/pi-coding-agent";
import {
  type EditorTheme,
  Key,
  matchesKey,
  type TUI,
} from "@mariozechner/pi-tui";
import { spawnSync, spawn, type ChildProcess } from "child_process";
import type WebSocketModule from "ws";

type WebSocketCtor = typeof WebSocketModule;

function getApiKey(): string | undefined {
  return process.env.ELEVENLABS_API_KEY;
}

function getLanguageCode(): string | undefined {
  return process.env.ELEVENLABS_LANGUAGE;
}

function checkRecAvailable(): boolean {
  const result = spawnSync("which", ["rec"], { encoding: "utf-8" });
  return result.status === 0;
}

// Shared recording state
let isRecording = false;
let recordingProc: ChildProcess | null = null;
let ws: InstanceType<WebSocketCtor> | null = null;
let currentTranscript = "";
let blinkInterval: NodeJS.Timeout | null = null;
let blinkState = true;
let onSubmit: (() => void) | null = null;
let onCancel: (() => void) | null = null;
let setStatusFn: ((text: string | undefined) => void) | null = null;
let setEditorTextFn: ((text: string) => void) | null = null;
let getEditorTextFn: (() => string) | null = null;
let currentTheme: Theme | null = null;
let prefixText = "";
let onPause: (() => void) | null = null;
let recordingStartTime = 0;

function formatTime(ms: number): string {
  const totalSeconds = Math.floor(ms / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
}

function updateStatusIndicator() {
  if (!setStatusFn || !currentTheme) return;
  const circle = blinkState
    ? currentTheme.fg("error", "●")
    : currentTheme.fg("muted", "○");
  const elapsed = formatTime(Date.now() - recordingStartTime);
  const hints = [
    currentTheme.fg("dim", "⏎") + currentTheme.fg("muted", " send"),
    currentTheme.fg("dim", "space") + currentTheme.fg("muted", " stop"),
    currentTheme.fg("dim", "esc") + currentTheme.fg("muted", " cancel"),
  ].join(currentTheme.fg("muted", ", "));
  setStatusFn(`${circle} ${currentTheme.fg("muted", elapsed)} ${hints}`);
}

function updateEditorText() {
  if (!setEditorTextFn || !currentTranscript) return;

  const separator = prefixText && !prefixText.endsWith(" ") ? " " : "";
  const fullText = prefixText + separator + currentTranscript;
  setEditorTextFn(fullText);
}

function startBlinking() {
  blinkState = true;
  updateStatusIndicator();
  blinkInterval = setInterval(() => {
    blinkState = !blinkState;
    updateStatusIndicator();
  }, 500);
}

function stopBlinking() {
  if (blinkInterval) {
    clearInterval(blinkInterval);
    blinkInterval = null;
  }
  setStatusFn?.(undefined);
}

/**
 * Custom editor that intercepts Enter/Escape during voice recording.
 */
class VoiceInputEditor extends CustomEditor {
  constructor(tui: TUI, theme: EditorTheme, keybindings: KeybindingsManager) {
    super(tui, theme, keybindings);
  }

  handleInput(data: string): void {
    if (isRecording) {
      // Enter or Ctrl+R: submit
      if (matchesKey(data, Key.enter) || matchesKey(data, Key.ctrl("r"))) {
        onSubmit?.();
        return;
      }
      // Escape: cancel
      if (matchesKey(data, Key.escape)) {
        onCancel?.();
        return;
      }
      // Space: stop recording, keep text for editing
      if (data === " ") {
        onPause?.();
        return;
      }
      // Ignore other input while recording
      return;
    }

    // Not recording - pass to parent for editing
    super.handleInput(data);
  }
}

interface RealtimeMessage {
  message_type: string;
  text?: string;
  session_id?: string;
  error?: string;
}

async function startRealtimeRecording(
  onTranscript: (text: string, isFinal: boolean) => void,
  onError: (error: string) => void,
): Promise<void> {
  const apiKey = getApiKey();
  if (!apiKey) {
    onError("ELEVENLABS_API_KEY not set");
    return;
  }

  currentTranscript = "";

  // Build WebSocket URL with query params
  const params = new URLSearchParams({
    model_id: "scribe_v2_realtime",
    sample_rate: "16000",
    audio_format: "pcm_16000",
  });

  const languageCode = getLanguageCode();
  if (languageCode) {
    params.set("language_code", languageCode);
  }

  const wsUrl = `wss://api.elevenlabs.io/v1/speech-to-text/realtime?${params.toString()}`;

  let WebSocketCtor: WebSocketCtor;
  try {
    const wsModule = (await import("ws")) as unknown as {
      default?: WebSocketCtor;
    };
    WebSocketCtor = wsModule.default ?? (wsModule as unknown as WebSocketCtor);
  } catch (error) {
    onError(
      `Failed to load ws dependency: ${error instanceof Error ? error.message : String(error)}`,
    );
    return;
  }

  const wsInstance = new WebSocketCtor(wsUrl, {
    headers: {
      "xi-api-key": apiKey,
    },
  });
  ws = wsInstance;

  wsInstance.on("open", () => {
    // Start timer
    recordingStartTime = Date.now();

    // Start recording and pipe to WebSocket
    // Use shell: false and detached to prevent terminal interference
    recordingProc = spawn(
      "rec",
      [
        "-q",
        "-c",
        "1",
        "-r",
        "16000",
        "-b",
        "16",
        "-e",
        "signed-integer",
        "-t",
        "raw",
        "-",
      ],
      {
        stdio: ["ignore", "pipe", "pipe"],
        detached: true,
      },
    );

    // Prevent stderr from affecting terminal
    recordingProc.stderr?.on("data", () => {});

    // Save existing text as prefix
    prefixText = getEditorTextFn?.() || "";

    // Workaround: setting initial text fixes cursor positioning bug when editor is empty
    // Show placeholder while waiting for transcription
    if (!prefixText) {
      setEditorTextFn?.("Say something...");
    }

    isRecording = true;
    startBlinking();

    recordingProc.stdout?.on("data", (chunk: Buffer) => {
      if (ws?.readyState === 1) {
        // Send audio chunk as base64
        ws.send(
          JSON.stringify({
            message_type: "input_audio_chunk",
            audio_base_64: chunk.toString("base64"),
          }),
        );
      }
    });

    recordingProc.on("error", (err) => {
      onError(`Recording error: ${err.message}`);
      cleanup();
    });

    recordingProc.on("close", () => {
      // Recording stopped - no need to send commit, VAD handles it
    });
  });

  ws.on("message", (data) => {
    try {
      const msg = JSON.parse(String(data)) as RealtimeMessage;

      if (msg.message_type === "partial_transcript" && msg.text) {
        currentTranscript = msg.text.trim();
        onTranscript(currentTranscript, false);
        updateEditorText();
      } else if (msg.message_type === "committed_transcript" && msg.text) {
        currentTranscript = msg.text.trim();
        onTranscript(currentTranscript, true);
        updateEditorText();
      } else if (msg.message_type === "error" && msg.error) {
        onError(msg.error);
      }
    } catch {
      // Ignore parse errors
    }
  });

  ws.on("error", (err) => {
    onError(`WebSocket error: ${err.message}`);
    cleanup();
  });

  ws.on("close", () => {
    // WebSocket closed
  });
}

function cleanup() {
  if (recordingProc) {
    recordingProc.kill("SIGTERM");
    recordingProc = null;
  }
  if (ws) {
    ws.close();
    ws = null;
  }
  isRecording = false;
  stopBlinking();
}

function stopRecording(): string {
  const transcript = currentTranscript;

  if (recordingProc) {
    recordingProc.kill("SIGTERM");
    recordingProc = null;
  }

  // Give WebSocket a moment to receive final transcript
  setTimeout(() => {
    if (ws) {
      ws.close();
      ws = null;
    }
  }, 500);

  isRecording = false;
  stopBlinking();
  currentTranscript = "";

  // Clear editor after stopping
  setEditorTextFn?.("");

  return transcript;
}

function cancelRecording() {
  cleanup();
  currentTranscript = "";
  // Restore original text
  setEditorTextFn?.(prefixText);
  prefixText = "";
}

function pauseRecording() {
  // Stop recording but keep the text for editing
  if (recordingProc) {
    recordingProc.kill("SIGTERM");
    recordingProc = null;
  }
  if (ws) {
    ws.close();
    ws = null;
  }

  isRecording = false;
  stopBlinking();

  // Add space at the end (user pressed space to stop)
  const currentText = getEditorTextFn?.() || "";
  setEditorTextFn?.(currentText + " ");

  // Clear status - user is now in normal editing mode
  setStatusFn?.(undefined);
}

export default function (pi: ExtensionAPI) {
  const recAvailable = checkRecAvailable();

  if (!recAvailable) {
    pi.on("session_start", (_event, ctx) => {
      ctx.ui.notify(
        "Voice input disabled: missing sox (brew install sox)",
        "warning",
      );
    });
    return;
  }

  pi.on("session_start", (_event, ctx) => {
    if (!getApiKey()) {
      ctx.ui.notify(
        "Voice input disabled: missing ELEVENLABS_API_KEY",
        "warning",
      );
    }

    // Install custom editor
    ctx.ui.setEditorComponent((tui, theme, keybindings) => {
      return new VoiceInputEditor(tui, theme, keybindings);
    });

    // Store status setter, editor text getter/setter, and theme
    setStatusFn = (text) => ctx.ui.setStatus("voice", text);
    setEditorTextFn = (text) => ctx.ui.setEditorText(text);
    getEditorTextFn = () => ctx.ui.getEditorText();
    currentTheme = ctx.ui.theme;
  });

  // Set up callbacks
  onSubmit = () => {
    // Get current text from editor (includes prefix + transcript)
    const fullText = (getEditorTextFn?.() || "").trim();

    // Clean up
    if (isRecording) {
      stopRecording();
    }
    prefixText = "";
    currentTranscript = "";
    setEditorTextFn?.("");

    if (fullText) {
      pi.sendUserMessage(fullText);
    }
  };

  onCancel = () => {
    cancelRecording();
  };

  onPause = () => {
    pauseRecording();
  };

  // Ctrl+R: start recording (or submit if already recording)
  pi.registerShortcut("`", {
    description: "Record voice input",
    handler: async (ctx) => {
      if (!ctx.hasUI) return;
      if (!getApiKey()) {
        ctx.ui.notify("ELEVENLABS_API_KEY not set", "error");
        return;
      }

      if (isRecording) {
        // Submit
        const text = stopRecording();
        if (text?.trim()) {
          pi.sendUserMessage(text.trim());
        } else {
          ctx.ui.notify("No speech detected", "warning");
        }
      } else {
        // Start realtime recording
        startRealtimeRecording(
          (_text, _isFinal) => {
            // Transcript updated - status already updates via updateStatus()
          },
          (error) => {
            ctx.ui.notify(error, "error");
            cleanup();
          },
        );
      }
    },
  });
}
