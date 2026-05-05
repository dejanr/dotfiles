/*
 * Adapted from pi-terminal-signals by Lucas Meijer:
 * https://github.com/lucasmeijer/pi-terminal-signals
 */

import { execFile } from "node:child_process";
import { promisify } from "node:util";

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";

const execFileAsync = promisify(execFile);
const osc = "\x1b]";
const bell = "\x07";

function canWriteTerminalSignal(ctx: ExtensionContext) {
  return ctx.hasUI && process.stdout.isTTY;
}

function writeOsc(sequence: string) {
  const signal = `${osc}${sequence}${bell}`;
  if (process.env.TMUX) {
    process.stdout.write(`\x1bPtmux;\x1b${signal}\x1b\\`);
    return;
  }

  process.stdout.write(signal);
}

function startProgress() {
  writeOsc("9;4;3");
}

function stopProgress() {
  writeOsc("9;4;0");
  writeOsc("133;D;0");
}

function tmuxPaneId() {
  return process.env.TMUX_PANE;
}

async function tmux(args: string[]) {
  return execFileAsync("tmux", args, { timeout: 1000 });
}

async function setTmuxRunning(running: boolean) {
  const paneId = tmuxPaneId();
  if (!paneId) return;

  try {
    await tmux(["set-option", "-pt", paneId, "@pi_pane_running", running ? "1" : "0"]);
    await tmux(["set-window-option", "-t", paneId, "@pi_running", running ? "1" : "0"]);
  } catch {
    return;
  }
}

async function setTmuxUnread() {
  const paneId = tmuxPaneId();
  if (!paneId) return;

  try {
    const { stdout } = await tmux(["display-message", "-pt", paneId, "#{window_active}"]);
    if (stdout.trim() === "1") return;
    await tmux(["set-window-option", "-t", paneId, "@pi_unread", "1"]);
  } catch {
    return;
  }
}

async function notifyFinished() {
  await setTmuxUnread();
}

export default function terminalSignals(pi: ExtensionAPI) {
  let active = false;

  async function start(ctx: ExtensionContext) {
    if (active || !ctx.hasUI) return;
    active = true;
    if (canWriteTerminalSignal(ctx)) startProgress();
    await setTmuxRunning(true);
  }

  async function stop(ctx: ExtensionContext) {
    if (!active) return false;
    active = false;
    if (canWriteTerminalSignal(ctx)) stopProgress();
    await setTmuxRunning(false);
    return true;
  }

  pi.on("agent_start", async (_event, ctx) => {
    await start(ctx);
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    await stop(ctx);
  });

  pi.on("agent_end", async (_event, ctx) => {
    const stopped = await stop(ctx);
    if (stopped && !ctx.hasPendingMessages()) await notifyFinished();
  });
}
