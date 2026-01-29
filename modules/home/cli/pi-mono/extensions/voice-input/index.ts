/**
 * Voice Input Extension
 *
 * Press backtick (`) to start/stop voice recording. Audio is transcribed
 * via ElevenLabs in real-time and sent as a user message to the agent.
 *
 * Requires:
 * - ELEVENLABS_API_KEY in env
 * - ffmpeg with PulseAudio support
 *
 * Optional:
 * - ELEVENLABS_LANGUAGE - ISO-639-1/3 language code (e.g., "en", "ru", "de")
 * - PULSE_INPUT_DEVICE - PulseAudio input device (auto-detected if not set)
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

// ============================================================================
// Types
// ============================================================================

type WebSocketCtor = typeof WebSocketModule;
type WebSocketInstance = InstanceType<WebSocketCtor>;

type RecordingState =
  | { status: "idle" }
  | { status: "recording"; startTime: number; prefixText: string }
  | { status: "stopping" };

interface UIHandlers {
  setStatus: (text: string | undefined) => void;
  setEditorText: (text: string) => void;
  getEditorText: () => string;
  notify: (message: string, level: "info" | "warning" | "error") => void;
  theme: Theme;
}

interface RecordingSession {
  process: ChildProcess;
  websocket: WebSocketInstance;
  transcript: string;
}

// ============================================================================
// Environment & System Checks
// ============================================================================

const getApiKey = (): string | undefined => process.env.ELEVENLABS_API_KEY;
const getLanguageCode = (): string | undefined =>
  process.env.ELEVENLABS_LANGUAGE;

const checkFfmpegAvailable = (): boolean => {
  const result = spawnSync("which", ["ffmpeg"], { encoding: "utf-8" });
  return result.status === 0;
};

const getPulseInputDevice = (): string | undefined => {
  const envDevice = process.env.PULSE_INPUT_DEVICE;
  if (envDevice) return envDevice;

  // Try pactl first (PulseAudio)
  const pactlResult = spawnSync("pactl", ["list", "sources", "short"], {
    encoding: "utf-8",
  });
  if (pactlResult.status === 0) {
    for (const line of pactlResult.stdout.split("\n")) {
      if (line.includes("input") && line.includes("analog-stereo")) {
        const parts = line.split("\t");
        if (parts[1]) return parts[1];
      }
    }
  }

  // Fallback to pw-cli (PipeWire)
  const pwResult = spawnSync("pw-cli", ["list-objects"], {
    encoding: "utf-8",
  });
  if (pwResult.status === 0) {
    const lines = pwResult.stdout.split("\n");
    for (const line of lines) {
      if (line.includes("node.name") && line.includes("alsa_input")) {
        const match = line.match(/"([^"]+)"/);
        if (match) return match[1];
      }
    }
  }

  return undefined;
};

// ============================================================================
// Recording Controller
// ============================================================================

class RecordingController {
  private state: RecordingState = { status: "idle" };
  private session: RecordingSession | null = null;
  private blinkInterval: NodeJS.Timeout | null = null;
  private blinkState = true;
  private ui: UIHandlers | null = null;

  setUI(handlers: UIHandlers): void {
    this.ui = handlers;
  }

  getState(): RecordingState {
    return this.state;
  }

  isRecording(): boolean {
    return this.state.status === "recording";
  }

  async start(): Promise<void> {
    if (this.state.status !== "idle") return;

    const apiKey = getApiKey();
    if (!apiKey) {
      this.ui?.notify("ELEVENLABS_API_KEY not set", "error");
      return;
    }

    const inputDevice = getPulseInputDevice();
    if (!inputDevice) {
      this.ui?.notify("No PulseAudio input device found", "error");
      return;
    }

    const prefixText = this.ui?.getEditorText() || "";
    this.state = { status: "recording", startTime: Date.now(), prefixText };

    this.startStatusBlink();

    try {
      await this.createSession(apiKey, inputDevice);
    } catch (error) {
      this.handleError(error instanceof Error ? error.message : String(error));
    }
  }

  stop(): string {
    if (this.state.status !== "recording") return "";

    const transcript = this.session?.transcript || "";
    this.state = { status: "stopping" };

    this.cleanupSession();
    this.stopStatusBlink();
    this.ui?.setEditorText("");

    this.state = { status: "idle" };
    return transcript;
  }

  cancel(): void {
    if (this.state.status !== "recording") return;

    const prefixText = this.state.prefixText;
    this.state = { status: "stopping" };

    this.cleanupSession();
    this.stopStatusBlink();
    this.ui?.setEditorText(prefixText);

    this.state = { status: "idle" };
  }

  pause(): void {
    if (this.state.status !== "recording") return;

    this.state = { status: "stopping" };

    const currentText = this.ui?.getEditorText() || "";
    this.cleanupSession();
    this.stopStatusBlink();
    this.ui?.setEditorText(currentText + " ");

    this.state = { status: "idle" };
  }

  private async createSession(
    apiKey: string,
    inputDevice: string,
  ): Promise<void> {
    const websocket = await this.createWebSocket(apiKey);
    const process = this.createRecordingProcess(inputDevice);

    this.session = { process, websocket, transcript: "" };

    this.setupProcessHandlers(process, websocket);
    this.setupWebSocketHandlers(websocket);
  }

  private async createWebSocket(apiKey: string): Promise<WebSocketInstance> {
    const params = new URLSearchParams({
      model_id: "scribe_v2_realtime",
      sample_rate: "16000",
      audio_format: "pcm_16000",
    });

    const languageCode = getLanguageCode();
    if (languageCode) {
      params.set("language_code", languageCode);
    }

    const wsUrl = `wss://api.elevenlabs.io/v1/speech-to-text/realtime?${params}`;

    const wsModule = (await import("ws")) as unknown as {
      default?: WebSocketCtor;
    };
    const WebSocketCtor =
      wsModule.default ?? (wsModule as unknown as WebSocketCtor);

    return new WebSocketCtor(wsUrl, {
      headers: { "xi-api-key": apiKey },
    });
  }

  private createRecordingProcess(inputDevice: string): ChildProcess {
    return spawn(
      "ffmpeg",
      [
        "-loglevel",
        "quiet",
        "-f",
        "pulse",
        "-i",
        inputDevice,
        "-f",
        "s16le",
        "-ar",
        "16000",
        "-ac",
        "1",
        "-",
      ],
      { stdio: ["ignore", "pipe", "pipe"], detached: true },
    );
  }

  private setupProcessHandlers(
    process: ChildProcess,
    websocket: WebSocketInstance,
  ): void {
    process.stderr?.on("data", () => {});

    process.stdout?.on("data", (chunk: Buffer) => {
      if (this.state.status !== "recording") return;
      if (websocket.readyState === 1) {
        websocket.send(
          JSON.stringify({
            message_type: "input_audio_chunk",
            audio_base_64: chunk.toString("base64"),
          }),
        );
      }
    });

    process.on("error", (err) => {
      this.handleError(`Recording error: ${err.message}`);
    });
  }

  private setupWebSocketHandlers(websocket: WebSocketInstance): void {
    websocket.on("message", (data: unknown) => {
      if (this.state.status !== "recording" || !this.session) return;

      try {
        const msg = JSON.parse(String(data)) as {
          message_type: string;
          text?: string;
          error?: string;
        };

        if (
          (msg.message_type === "partial_transcript" ||
            msg.message_type === "committed_transcript") &&
          msg.text
        ) {
          this.session.transcript = msg.text.trim();
          this.updateEditorWithTranscript();
        } else if (msg.message_type === "error" && msg.error) {
          this.handleError(msg.error);
        }
      } catch {
        // Ignore parse errors
      }
    });

    websocket.on("error", (err: Error) => {
      this.handleError(`WebSocket error: ${err.message}`);
    });
  }

  private updateEditorWithTranscript(): void {
    if (this.state.status !== "recording" || !this.session?.transcript) return;

    const prefix = this.state.prefixText;
    const separator = prefix && !prefix.endsWith(" ") ? " " : "";
    this.ui?.setEditorText(prefix + separator + this.session.transcript);
  }

  private handleError(message: string): void {
    this.ui?.notify(message, "error");
    if (this.state.status === "recording") {
      const prefixText = this.state.prefixText;
      this.state = { status: "stopping" };
      this.cleanupSession();
      this.stopStatusBlink();
      this.ui?.setEditorText(prefixText);
      this.state = { status: "idle" };
    }
  }

  private cleanupSession(): void {
    if (this.session) {
      this.session.process.kill("SIGTERM");
      this.session.websocket.close();
      this.session = null;
    }
  }

  private startStatusBlink(): void {
    this.blinkState = true;
    this.updateStatus();
    this.blinkInterval = setInterval(() => {
      this.blinkState = !this.blinkState;
      this.updateStatus();
    }, 500);
  }

  private stopStatusBlink(): void {
    if (this.blinkInterval) {
      clearInterval(this.blinkInterval);
      this.blinkInterval = null;
    }
  }

  showIdleStatus(): void {
    if (!this.ui) return;
    const theme = this.ui.theme;
    this.ui.setStatus(theme.fg("success", "● ") + theme.fg("muted", "ready"));
  }

  showSendingStatus(): void {
    if (!this.ui) return;
    const theme = this.ui.theme;
    this.ui.setStatus(theme.fg("success", "● ") + theme.fg("muted", "ready"));
  }

  clearStatus(): void {
    this.ui?.setStatus(undefined);
  }

  private updateStatus(): void {
    if (this.state.status !== "recording" || !this.ui) return;

    const theme = this.ui.theme;
    const circle = this.blinkState
      ? theme.fg("error", "●")
      : theme.fg("muted", "○");

    const elapsed = this.formatTime(Date.now() - this.state.startTime);

    this.ui.setStatus(
      `${circle} ${theme.fg("warning", "recording")} ${theme.fg("muted", elapsed)}`,
    );
  }

  private formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
  }
}

// ============================================================================
// Voice Input Editor
// ============================================================================

class VoiceInputEditor extends CustomEditor {
  constructor(
    tui: TUI,
    theme: EditorTheme,
    keybindings: KeybindingsManager,
    private controller: RecordingController,
    private handlers: {
      onSubmit: () => void;
      onCancel: () => void;
      onPause: () => void;
    },
  ) {
    super(tui, theme, keybindings);
  }

  handleInput(data: string): void {
    if (this.controller.isRecording()) {
      if (matchesKey(data, Key.enter) || matchesKey(data, Key.ctrl("r"))) {
        this.handlers.onSubmit();
        return;
      }
      if (matchesKey(data, Key.escape)) {
        this.handlers.onCancel();
        return;
      }
      if (data === " ") {
        this.handlers.onPause();
        return;
      }
      return; // Ignore other input while recording
    }

    super.handleInput(data);
  }
}

// ============================================================================
// Extension Entry Point
// ============================================================================

export default function (pi: ExtensionAPI) {
  if (!checkFfmpegAvailable()) {
    pi.on("session_start", (_event, ctx) => {
      ctx.ui.notify("Voice input disabled: ffmpeg not found", "warning");
    });
    return;
  }

  const controller = new RecordingController();

  const submitRecording = () => {
    const text = controller.stop();
    if (text.trim()) {
      pi.sendUserMessage(text.trim());
    }
  };

  pi.on("session_start", (_event, ctx) => {
    if (!getApiKey()) {
      ctx.ui.notify(
        "Voice input disabled: missing ELEVENLABS_API_KEY",
        "warning",
      );
    }

    controller.setUI({
      setStatus: (text) => ctx.ui.setStatus("voice", text),
      setEditorText: (text) => ctx.ui.setEditorText(text),
      getEditorText: () => ctx.ui.getEditorText(),
      notify: (message, level) => ctx.ui.notify(message, level),
      theme: ctx.ui.theme,
    });

    // Show idle status on start
    if (getApiKey()) {
      controller.showIdleStatus();
    }

    ctx.ui.setEditorComponent((tui, theme, keybindings) => {
      return new VoiceInputEditor(tui, theme, keybindings, controller, {
        onSubmit: submitRecording,
        onCancel: () => {
          controller.cancel();
          controller.showIdleStatus();
        },
        onPause: () => {
          controller.pause();
          controller.showIdleStatus();
        },
      });
    });
  });

  pi.registerShortcut("`", {
    description: "Record voice input",
    handler: async (ctx) => {
      if (!ctx.hasUI) return;
      if (!getApiKey()) {
        ctx.ui.notify("ELEVENLABS_API_KEY not set", "error");
        return;
      }

      if (controller.isRecording()) {
        controller.showSendingStatus();
        const text = controller.stop();
        if (text.trim()) {
          pi.sendUserMessage(text.trim());
        } else {
          ctx.ui.notify("No speech detected", "warning");
          controller.showIdleStatus();
        }
      } else {
        await controller.start();
      }
    },
  });

  // Show idle status after message is sent
  pi.on("input", () => {
    if (!controller.isRecording()) {
      controller.showIdleStatus();
    }
  });
}
