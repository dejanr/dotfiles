import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import type { IncomingMessage, ServerResponse } from "node:http";
import { test } from "node:test";
import { create, fromBinary, toBinary } from "@bufbuild/protobuf";
import { BinaryReader, BinaryWriter, WireType } from "@bufbuild/protobuf/wire";
import { ValueSchema } from "@bufbuild/protobuf/wkt";
import {
  AgentClientMessageSchema,
  AgentServerMessageSchema,
  ExecServerMessageSchema,
  McpArgsSchema,
  McpToolDefinitionSchema,
  ReadArgsSchema,
  type AgentServerMessage,
} from "./proto/agent_pb.js";
import { __testInternals, stopProxy, writeSSEStreamForTests } from "./proxy.js";

function frame(bytes: Uint8Array): Buffer {
  const framed = Buffer.alloc(bytes.length + 5);
  framed.writeUInt32BE(bytes.length, 1);
  framed.set(bytes, 5);
  return framed;
}

function wireFields(bytes: Uint8Array) {
  const reader = new BinaryReader(bytes);
  const fields: Array<{ number: number; value: Uint8Array | number }> = [];
  while (reader.pos < reader.len) {
    const [number, wireType] = reader.tag();
    if (wireType === WireType.LengthDelimited) fields.push({ number, value: reader.bytes() });
    else if (wireType === WireType.Varint) fields.push({ number, value: reader.uint32() });
    else reader.skip(wireType);
  }
  return fields;
}

function bytesField(bytes: Uint8Array, number: number): Uint8Array {
  const field = wireFields(bytes).find((field) => field.number === number);
  assert.ok(field?.value instanceof Uint8Array, `Missing message field ${number}`);
  return field.value;
}

function stateRequest(identifiers: string[], kickOnly = false) {
  const args = new BinaryWriter();
  for (const identifier of identifiers) args.tag(1, WireType.LengthDelimited).string(identifier);
  if (kickOnly) args.tag(2, WireType.Varint).bool(true);
  const exec = create(ExecServerMessageSchema, { id: 7, execId: "state-fixture" });
  exec.$unknown = [
    { no: 36, wireType: WireType.LengthDelimited, data: new BinaryWriter().bytes(args.finish()).finish() },
    { no: 55, wireType: WireType.Varint, data: new Uint8Array([0]) },
  ];
  return create(AgentServerMessageSchema, { message: { case: "execServerMessage", value: exec } });
}

function streamHarness() {
  let dataCallback: ((chunk: Buffer) => void) | undefined;
  let closeCallback: ((code: number) => void) | undefined;
  const sent: Uint8Array[] = [];
  const output: string[] = [];
  const bridge = {
    alive: true,
    proc: { kill: () => { bridge.alive = false; closeCallback?.(0); return true; } },
    write: (bytes: Uint8Array) => { sent.push(bytes); },
    end: () => {},
    unref: () => {},
    onData: (callback: (chunk: Buffer) => void) => { dataCallback = callback; },
    onClose: (callback: (code: number) => void) => { closeCallback = callback; },
    getStderr: () => ({ responseHeaders: { status: 200, grpcStatus: null } }),
  };
  const req = new EventEmitter();
  const res = Object.assign(new EventEmitter(), {
    headersSent: false,
    writableEnded: false,
    destroyed: false,
    writeHead: () => { res.headersSent = true; },
    write: (chunk: string) => { output.push(chunk); return true; },
    end: () => { res.writableEnded = true; },
  });
  const tools = [
    create(McpToolDefinitionSchema, { name: "read", toolName: "read", providerIdentifier: "pi" }),
    create(McpToolDefinitionSchema, { name: "search", toolName: "search", providerIdentifier: "other" }),
  ];
  __testInternals.sessionBridges.set("state-fixture", bridge);
  const heartbeatTimer = setInterval(() => {}, 5000);
  writeSSEStreamForTests({
    bridge, heartbeatTimer, mcpTools: tools, modelId: "grok-4.7",
    bridgeKey: "state-fixture", convKey: "state-fixture", completedTurns: [],
    currentTurn: { userText: "read fixture", images: [], steps: [] },
    req: req as IncomingMessage, res: res as unknown as ServerResponse,
  });
  return {
    sent, output, tools,
    emit: (message: AgentServerMessage) => dataCallback?.(frame(toBinary(AgentServerMessageSchema, message))),
  };
}

for (const { identifiers, expected, kickOnly } of [
  { identifiers: ["pi"], expected: ["pi"], kickOnly: false },
  { identifiers: [], expected: ["pi", "other"], kickOnly: false },
  { identifiers: ["missing"], expected: [], kickOnly: false },
  { identifiers: ["pi"], expected: ["pi"], kickOnly: true },
]) {
  test(`MCP state discovery filters ${JSON.stringify(identifiers)}, kick=${kickOnly}`, () => {
    const harness = streamHarness();
    try {
      harness.emit(stateRequest(identifiers, kickOnly));
      assert.equal(harness.sent.length, 1, "The real stream dispatcher must answer field 36 instead of stalling");
      const response = fromBinary(AgentClientMessageSchema, harness.sent[0].subarray(5));
      assert.equal(response.message.case, "execClientMessage");
      if (response.message.case !== "execClientMessage") throw new Error("Wrong envelope");
      const exec = response.message.value;
      assert.equal(exec.id, 7);
      assert.equal(exec.execId, "state-fixture");
      const state = exec.$unknown?.find(({ no }) => no === 36);
      assert.ok(state);
      const result = new BinaryReader(state.data).bytes();
      const success = bytesField(result, 1);
      const servers = wireFields(success).filter(({ number }) => number === 1);
      assert.equal(servers.length, expected.length);
      for (const [index, field] of servers.entries()) {
        assert.ok(field.value instanceof Uint8Array);
        const server = field.value;
        assert.equal(new TextDecoder().decode(bytesField(server, 1)), expected[index]);
        assert.equal(new TextDecoder().decode(bytesField(server, 2)), expected[index]);
        assert.equal(new TextDecoder().decode(bytesField(server, 7)), "connected");
        const tool = fromBinary(McpToolDefinitionSchema, bytesField(server, 5));
        assert.deepEqual(tool, harness.tools.find(({ providerIdentifier }) => providerIdentifier === expected[index]));
      }
      assert.equal(harness.output.join("").includes('"tool_calls"'), false, "State discovery must not execute a tool");
    } finally {
      stopProxy();
    }
  });
}

test("MCP state reply allows the same stream to hand a read call to Pi", () => {
  const harness = streamHarness();
  try {
    harness.emit(stateRequest(["pi"]));
    assert.equal(harness.sent.length, 1);
    harness.emit(create(AgentServerMessageSchema, { message: {
      case: "execServerMessage", value: create(ExecServerMessageSchema, {
        id: 8, execId: "read-fixture", message: { case: "mcpArgs", value: create(McpArgsSchema, {
          name: "read", toolName: "read", providerIdentifier: "pi", toolCallId: "read-call",
          args: { path: toBinary(ValueSchema, create(ValueSchema, { kind: { case: "stringValue", value: "/synthetic/fixture.txt" } })) },
        }) },
      }),
    } }));
    const output = harness.output.join("");
    assert.ok(output.includes('"name":"read"'));
    assert.ok(output.includes("/synthetic/fixture.txt"));
    assert.ok(output.includes('"finish_reason":"tool_calls"'));
  } finally {
    stopProxy();
  }
});

test("legacy native reads remain rejected rather than bypassing Pi tools", () => {
  const harness = streamHarness();
  try {
    harness.emit(create(AgentServerMessageSchema, { message: {
      case: "execServerMessage", value: create(ExecServerMessageSchema, {
        id: 9, execId: "native-fixture", message: {
          case: "readArgs", value: create(ReadArgsSchema, { path: "/synthetic/fixture.txt" }),
        },
      }),
    } }));
    assert.equal(harness.sent.length, 1);
    const response = fromBinary(AgentClientMessageSchema, harness.sent[0].subarray(5));
    assert.equal(response.message.case, "execClientMessage");
    if (response.message.case !== "execClientMessage") throw new Error("Wrong envelope");
    assert.equal(response.message.value.message.case, "readResult");
    if (response.message.value.message.case !== "readResult") throw new Error("Wrong result");
    assert.equal(response.message.value.message.value.result.case, "rejected");
    assert.equal(harness.output.join("").includes('"tool_calls"'), false);
  } finally {
    stopProxy();
  }
});
