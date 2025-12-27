{
  pkgs,
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.darwin.gui.sketchybar;
in
{
  options.modules.darwin.gui.sketchybar = {
    enable = mkEnableOption "sketchybar";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.jq ];
  };
}
