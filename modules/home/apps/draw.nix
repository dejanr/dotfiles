{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.apps.draw;
  draw = inputs.draw.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  options.modules.apps.draw.enable = lib.mkEnableOption "Draw editor and MCP server";

  config = lib.mkIf cfg.enable {
    home.packages = [
      draw.draw
      draw.draw-mcp
    ]
    ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin draw.draw-app;
  };
}
