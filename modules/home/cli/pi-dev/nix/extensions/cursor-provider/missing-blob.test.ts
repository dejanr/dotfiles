import assert from "node:assert/strict";
import { test } from "node:test";
import { create, fromBinary, toBinary } from "@bufbuild/protobuf";
import {
  AgentClientMessageSchema,
  AgentServerMessageSchema,
  GetBlobArgsSchema,
  KvServerMessageSchema,
  type AgentClientMessage,
} from "./proto/agent_pb.js";
import { getProxyAuthToken, setBridgeFactoryForTests, startProxy, stopProxy, type BridgeFactory } from "./proxy.js";

function frame(bytes: Uint8Array, flags = 0): Buffer {
  const result = Buffer.alloc(bytes.length + 5);
  result[0] = flags;
  result.writeUInt32BE(bytes.length, 1);
  result.set(bytes, 5);
  return result;
}

function endStream(error?: { code: string; message: string }): Buffer {
  return frame(Buffer.from(JSON.stringify(error ? { error } : {})), 2);
}

for (const scenario of ["history", "archive"] as const) {
  test(`retry serves rebuilt ${scenario} blobs instead of poisoning the conversation checkpoint`, async () => {
    let attempts = 0;
    const missing: string[] = [];
    setBridgeFactoryForTests((): ReturnType<BridgeFactory> => {
      const attempt = ++attempts;
      let alive = true;
      let onData: ((chunk: Buffer) => void) | undefined;
      let onClose: ((code: number) => void) | undefined;
      let request: AgentClientMessage | undefined;
      const close = () => {
        if (!alive) return;
        alive = false;
        queueMicrotask(() => onClose?.(0));
      };
      return {
        get alive() { return alive; },
        proc: { kill: () => { close(); return true; } },
        end: close,
        unref: () => {},
        getStderr: () => ({}),
        onClose: (callback) => { onClose = callback; },
        write: (bytes) => {
          const message = fromBinary(AgentClientMessageSchema, bytes.subarray(5));
          if (message.message.case === "runRequest") request = message;
          if (message.message.case === "kvClientMessage") {
            const kv = message.message.value;
            if (kv.message.case !== "getBlobResult") return;
            const found = kv.message.value.blobData?.length;
            if (!found) missing.push(`attempt ${attempt}`);
            queueMicrotask(() => onData?.(endStream(found ? undefined : {
              code: "failed_precondition",
              message: "Conversation data missing\n\nThis conversation's data is missing and can't be restored. Start a new chat to continue. (missing blob fixture)",
            })));
          }
        },
        onData: (callback) => {
          onData = callback;
          queueMicrotask(() => {
            assert.equal(request?.message.case, "runRequest");
            if (request?.message.case !== "runRequest") return;
            const checkpoint = request.message.value.conversationState!;
            if (attempt === 1) {
              if (scenario === "archive") {
                checkpoint.turns = Array.from({ length: 21 }, () => checkpoint.turns[0]);
                callback(frame(toBinary(AgentServerMessageSchema, create(AgentServerMessageSchema, {
                  message: { case: "conversationCheckpointUpdate", value: checkpoint },
                }))));
              }
              callback(endStream({ code: "unavailable", message: "transient fixture" }));
              return;
            }
            const blobId = scenario === "history" ? checkpoint.turns[0] : checkpoint.summaryArchives.at(-1);
            assert.ok(blobId, "Retry must include the rebuilt history reference");
            callback(frame(toBinary(AgentServerMessageSchema, create(AgentServerMessageSchema, {
              message: { case: "conversationCheckpointUpdate", value: checkpoint },
            }))));
            callback(frame(toBinary(AgentServerMessageSchema, create(AgentServerMessageSchema, {
              message: { case: "kvServerMessage", value: create(KvServerMessageSchema, {
                id: 1, message: { case: "getBlobArgs", value: create(GetBlobArgsSchema, { blobId }) },
              }) },
            }))));
          });
        },
      };
    });
    try {
      const port = await startProxy(async () => "synthetic-token");
      for (let turn = 0; turn < 2; turn++) {
        const response = await fetch(`http://127.0.0.1:${port}/v1/chat/completions`, {
          method: "POST",
          headers: { Authorization: `Bearer ${getProxyAuthToken()}`, "Content-Type": "application/json" },
          body: JSON.stringify({ model: "grok-4.7-high", stream: true, pi_session_id: "blob-fixture", messages: [
            { role: "user", content: "Earlier request" },
            { role: "assistant", content: "Earlier response" },
            { role: "user", content: turn ? "continue" : "read fixture" },
          ] }),
          signal: AbortSignal.timeout(5000),
        });
        const body = await response.text();
        assert.equal(body.includes("Conversation data missing"), false, body);
        assert.ok(body.includes('"finish_reason":"stop"'));
      }
      assert.deepEqual(missing, []);
      assert.equal(attempts, 3);
    } finally {
      stopProxy();
      setBridgeFactoryForTests();
    }
  });
}
