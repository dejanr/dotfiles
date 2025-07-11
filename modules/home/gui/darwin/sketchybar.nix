{ pkgs, lib, config, ... }:
with lib;
let
  cfg = config.modules.home.gui.darwin.sketchybar;
in
{
  options.modules.home.gui.darwin.sketchybar = { enable = mkEnableOption "sketchybar"; };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.jq ];
    home.file.".config/sketchybar".source = ./config;
  };
}
