import { create, toBinary } from "@bufbuild/protobuf";
import { BinaryReader, BinaryWriter, WireType } from "@bufbuild/protobuf/wire";
import {
  AgentClientMessageSchema,
  ExecClientMessageSchema,
  McpToolDefinitionSchema,
  type ExecServerMessage,
  type McpToolDefinition,
} from "./proto/agent_pb.js";

const MCP_STATE_FIELD = 36;

function requestedServers(data: Uint8Array): Set<string> {
  const reader = new BinaryReader(new BinaryReader(data).bytes());
  const identifiers = new Set<string>();
  while (reader.pos < reader.len) {
    const [number, wireType] = reader.tag();
    if (number === 1 && wireType === WireType.LengthDelimited) identifiers.add(reader.string());
    else reader.skip(wireType);
  }
  return identifiers;
}

function encodeState(tools: McpToolDefinition[], requested: Set<string>): Uint8Array {
  const servers = new Map<string, McpToolDefinition[]>();
  for (const tool of tools) {
    if (requested.size > 0 && !requested.has(tool.providerIdentifier)) continue;
    const serverTools = servers.get(tool.providerIdentifier) ?? [];
    serverTools.push(tool);
    servers.set(tool.providerIdentifier, serverTools);
  }

  const success = new BinaryWriter();
  for (const [identifier, serverTools] of servers) {
    const server = new BinaryWriter()
      .tag(1, WireType.LengthDelimited).string(identifier)
      .tag(2, WireType.LengthDelimited).string(identifier)
      .tag(7, WireType.LengthDelimited).string("connected");
    for (const tool of serverTools) {
      server.tag(5, WireType.LengthDelimited).bytes(toBinary(McpToolDefinitionSchema, tool));
    }
    success.tag(1, WireType.LengthDelimited).bytes(server.finish());
  }
  return new BinaryWriter().tag(1, WireType.LengthDelimited).bytes(success.finish()).finish();
}

export function encodeMcpStateResponse(
  exec: ExecServerMessage,
  tools: McpToolDefinition[],
): Uint8Array | undefined {
  if (exec.message.case !== undefined) return undefined;
  const field = exec.$unknown?.find(({ no, wireType }) =>
    no === MCP_STATE_FIELD && wireType === WireType.LengthDelimited,
  );
  if (!field) return undefined;

  // The pinned schema predates field 36; Buf retains its length-prefixed value in $unknown.
  const result = encodeState(tools, requestedServers(field.data));
  const response = create(ExecClientMessageSchema, { id: exec.id, execId: exec.execId });
  response.$unknown = [{
    no: MCP_STATE_FIELD,
    wireType: WireType.LengthDelimited,
    data: new BinaryWriter().bytes(result).finish(),
  }];
  return toBinary(AgentClientMessageSchema, create(AgentClientMessageSchema, {
    message: { case: "execClientMessage", value: response },
  }));
}
