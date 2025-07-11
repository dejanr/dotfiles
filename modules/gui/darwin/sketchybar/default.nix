{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.darwin.sketchybar;
in
{
  options.modules.darwin.sketchybar = { enable = mkEnableOption "sketchybar"; };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.jq ];
    home.file.".config/sketchybar".source = ./config;
  };
}
