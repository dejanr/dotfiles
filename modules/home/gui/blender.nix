{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.blender;
  blenderMcp = inputs.self.packages.${pkgs.stdenv.hostPlatform.system}.blender-mcp;
  blenderConfigDir =
    if pkgs.stdenv.isDarwin then "Library/Application Support/Blender" else ".config/blender";
  addonPath = "${blenderConfigDir}/${versions.majorMinor pkgs.blender.version}/scripts/addons/blender_mcp.py";

  blenderWithMcp = pkgs.writeShellScriptBin "blender-mcp" ''
    export DISABLE_TELEMETRY=true
    exec ${pkgs.blender}/bin/blender "$@" --addons blender_mcp
  '';

  piExtension = pkgs.writeText "pi-blender-mcp.ts" ''
    import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

    export default function (pi: ExtensionAPI) {
      pi.registerMcpServer("blender", {
        command: "${lib.getExe blenderMcp}",
        args: ["--host", "127.0.0.1", "--port", "9876"],
        enabled: false,
        exposure: "codemode",
        description: "Inspect and edit scenes in the running Blender instance.",
      });
    }
  '';
in
{
  options.modules.home.gui.blender = {
    enable = mkEnableOption "Blender with opt-in MCP integration";
  };

  config = mkIf cfg.enable {
    home.packages = [
      pkgs.blender
      blenderMcp
      blenderWithMcp
    ];

    home.file.${addonPath}.source = "${blenderMcp}/share/blender-mcp/blender_mcp.py";

    modules.home.cli.pi-dev.extraExtensions = [ piExtension ];
  };
}
