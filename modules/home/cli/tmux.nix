{ pkgs, lib, config, colors, ... }:

with lib;

let
  cfg = config.modules.home.cli.tmux;
  extraConfig = import ./tmux/config.nix {
    inherit colors;
  };
in
{
  options.modules.home.cli.tmux = { enable = mkEnableOption "tmux"; };
  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;

      sensibleOnTop = false;

      prefix = "C-s";

      extraConfig = extraConfig;
    };
  };
}
