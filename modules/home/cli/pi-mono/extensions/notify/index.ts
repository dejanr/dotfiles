/**
 * Desktop Notification Extension
 *
 * Sends a native desktop notification when the agent finishes.
 * Supports multiple terminal notification protocols:
 *
 * - OSC 777 (urxvt): Ghostty, iTerm2, WezTerm, foot, rxvt-unicode
 * - OSC 9 (iTerm2): iTerm2, WezTerm, mintty, ConEmu
 *
 * Note: Some terminals (like foot) suppress notifications when focused.
 * This is intentional to prevent notification spam.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

/**
 * Send a desktop notification using OSC escape sequences.
 * Sends both OSC 777 and OSC 9 for maximum compatibility.
 */
function notify(title: string, body: string): void {
  // Sanitize inputs: remove semicolons and control characters
  const safeTitle = title.replace(/[;\x00-\x1f]/g, "");
  const safeBody = body.replace(/[;\x00-\x1f]/g, "");

  // OSC 777 (urxvt-style): ESC ] 777 ; notify ; title ; body ST
  // Supported by: Ghostty, iTerm2, WezTerm, foot, urxvt
  process.stdout.write(`\x1b]777;notify;${safeTitle};${safeBody}\x1b\\`);

  // OSC 9 (iTerm2-style): ESC ] 9 ; message ST
  // Supported by: iTerm2, WezTerm, mintty, ConEmu
  // Only has body, no title - combine them
  const message = safeTitle ? `${safeTitle}: ${safeBody}` : safeBody;
  process.stdout.write(`\x1b]9;${message}\x1b\\`);
}

export default function (pi: ExtensionAPI) {
  // Track tools called during the current agent run
  let toolsCalled = new Set<string>();

  pi.on("agent_start", () => {
    toolsCalled = new Set();
  });

  pi.on("tool_call", (event) => {
    toolsCalled.add(event.toolName);
  });

  pi.on("agent_end", async (event) => {
    // Check if the last message indicates an error or abort
    const lastMessage = event.messages[event.messages.length - 1];
    const stopReason =
      lastMessage && "stopReason" in lastMessage
        ? (lastMessage as { stopReason?: string }).stopReason
        : undefined;

    if (stopReason === "error") {
      const errorMessage =
        lastMessage && "errorMessage" in lastMessage
          ? (lastMessage as { errorMessage?: string }).errorMessage
          : undefined;
      notify("Pi Error", errorMessage || "Unknown error");
      return;
    }

    if (stopReason === "aborted") {
      // Don't notify on user abort - intentional cancellation
      return;
    }

    // Build informative message based on what happened
    const body = getNotificationBody(toolsCalled);
    notify("Pi", body);
  });
}

function getNotificationBody(tools: Set<string>): string {
  // Question tool requires user input
  if (tools.has("question")) {
    return "Waiting for your choice";
  }

  return "Task completed";
}
