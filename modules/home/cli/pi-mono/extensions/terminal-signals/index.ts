/*
 * Adapted from pi-terminal-signals by Lucas Meijer:
 * https://github.com/lucasmeijer/pi-terminal-signals
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";

const osc = "\x1b]";
const bell = "\x07";

function canWriteTerminalSignal(ctx: ExtensionContext) {
  return ctx.hasUI && process.stdout.isTTY;
}

function writeOsc(sequence: string) {
  process.stdout.write(`${osc}${sequence}${bell}`);
}

function startProgress() {
  writeOsc("9;4;3");
}

function stopProgress() {
  writeOsc("9;4;0");
  writeOsc("133;D;0");
}

export default function terminalSignals(pi: ExtensionAPI) {
  let active = false;

  function start(ctx: ExtensionContext) {
    if (active || !canWriteTerminalSignal(ctx)) return;
    active = true;
    startProgress();
  }

  function stop(ctx: ExtensionContext) {
    if (!active || !canWriteTerminalSignal(ctx)) return;
    active = false;
    stopProgress();
  }

  pi.on("agent_start", async (_event, ctx) => {
    start(ctx);
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    stop(ctx);
  });

  pi.on("agent_end", async (_event, ctx) => {
    stop(ctx);
  });
}
