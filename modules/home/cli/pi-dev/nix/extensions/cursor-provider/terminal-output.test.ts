import assert from "node:assert/strict";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import {
  getProxyAuthToken,
  setBridgeFactoryForTests,
  startProxy,
  stopProxy,
  type BridgeFactory,
} from "./proxy.js";

const providerError = "Unable to reach the model provider";

function endStream(error?: { code: string; message: string }): Buffer {
  const payload = Buffer.from(JSON.stringify(error ? { error } : {}));
  const frame = Buffer.alloc(payload.length + 5);
  frame[0] = 2;
  frame.writeUInt32BE(payload.length, 1);
  frame.set(payload, 5);
  return frame;
}

function fakeBridge(frame: Buffer, exitCode = 0): ReturnType<BridgeFactory> {
  let alive = true;
  let onClose: ((code: number) => void) | undefined;
  const close = () => {
    if (!alive) return;
    alive = false;
    queueMicrotask(() => onClose?.(exitCode));
  };
  return {
    get alive() { return alive; },
    proc: { kill: () => { close(); return true; } },
    write: () => {},
    end: close,
    unref: () => {},
    onData: (callback) => queueMicrotask(() => {
      callback(frame);
      if (exitCode !== 0) close();
    }),
    onClose: (callback) => { onClose = callback; },
    getStderr: () => ({}),
  };
}

for (const scenario of ["retry-success", "retry-exhausted", "non-retryable", "bridge-failure", "non-stream-error", "debug", "unsafe-debug"] as const) {
  test(`${scenario}: provider diagnostics never write over Pi's terminal`, async (t) => {
    const directory = mkdtempSync(join(tmpdir(), "cursor-terminal-test-"));
    const debugFile = join(directory, "debug.log");
    const previousDebug = process.env.PI_CURSOR_PROVIDER_DEBUG;
    const previousDebugFile = process.env.PI_CURSOR_PROVIDER_DEBUG_FILE;
    process.env.PI_CURSOR_PROVIDER_DEBUG = scenario === "debug" || scenario === "unsafe-debug" ? "1" : "0";
    process.env.PI_CURSOR_PROVIDER_DEBUG_FILE = scenario === "unsafe-debug" ? directory : debugFile;
    const stderr: string[] = [];
    t.mock.method(process.stderr, "write", (chunk: unknown) => { stderr.push(String(chunk)); return true; });
    let attempts = 0;
    setBridgeFactoryForTests(() => {
      attempts++;
      if (scenario === "bridge-failure") return fakeBridge(Buffer.alloc(0), 1);
      const success = (scenario === "retry-success" || scenario === "debug" || scenario === "unsafe-debug") && attempts > 1;
      return fakeBridge(endStream(success ? undefined : {
        code: scenario === "non-retryable" ? "permission_denied" : "unavailable",
        message: providerError,
      }));
    });
    try {
      const port = await startProxy(async () => "synthetic-token");
      const response = await fetch(`http://127.0.0.1:${port}/v1/chat/completions`, {
        method: "POST",
        headers: { Authorization: `Bearer ${getProxyAuthToken()}`, "Content-Type": "application/json" },
        body: JSON.stringify({ model: "grok-4.7-high", stream: scenario !== "non-stream-error", messages: [{ role: "user", content: "synthetic test" }] }),
        signal: AbortSignal.timeout(5000),
      });
      const body = await response.text();
      assert.equal(attempts, scenario === "retry-exhausted" ? 3 : scenario === "retry-success" || scenario === "debug" || scenario === "unsafe-debug" ? 2 : 1);
      if (scenario === "retry-exhausted" || scenario === "non-retryable" || scenario === "non-stream-error") {
        assert.ok(body.includes(providerError), "Terminal failures must still reach Pi through the response");
        assert.ok(body.includes('"upstream_error"'));
      } else if (scenario === "bridge-failure") {
        assert.ok(body.includes('"bridge_terminated"'));
      } else {
        assert.ok(body.includes('"finish_reason":"stop"'));
        assert.equal(body.includes('"error"'), false);
      }
      assert.deepEqual(stderr, [], "Raw stderr bypasses Pi's renderer and overlaps the spinner/editor");
      if (scenario === "debug") {
        const log = readFileSync(debugFile, "utf8");
        assert.ok(log.includes('"stream.retry"'));
        assert.ok(log.includes(providerError));
        assert.equal(log.includes("synthetic-token"), false);
      }
    } finally {
      stopProxy();
      setBridgeFactoryForTests();
      t.mock.restoreAll();
      if (previousDebug === undefined) delete process.env.PI_CURSOR_PROVIDER_DEBUG;
      else process.env.PI_CURSOR_PROVIDER_DEBUG = previousDebug;
      if (previousDebugFile === undefined) delete process.env.PI_CURSOR_PROVIDER_DEBUG_FILE;
      else process.env.PI_CURSOR_PROVIDER_DEBUG_FILE = previousDebugFile;
      rmSync(directory, { recursive: true, force: true });
    }
  });
}
