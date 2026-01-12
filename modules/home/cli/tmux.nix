{
  pkgs,
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.modules.home.cli.tmux;
  colors = config.lib.stylix.colors;
in
{
  options.modules.home.cli.tmux = {
    enable = mkEnableOption "tmux";
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      sensibleOnTop = false;

      prefix = "C-s";
      escapeTime = 0;
      historyLimit = 50000;
      terminal = "tmux-256color";
      focusEvents = true;
      baseIndex = 1;
      keyMode = "vi";
      mouse = true;
      aggressiveResize = false;
      customPaneNavigationAndResize = true;
      resizeAmount = 5;

      extraConfig = import ./tmux/config.nix { inherit colors; };
    };
  };
}
