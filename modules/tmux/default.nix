{ pkgs, lib, config, colors, ... }:

with lib;

let
    cfg = config.modules.tmux;
    extraConfig = import ./config.nix {
        inherit colors;
    };
in {
    options.modules.tmux = { enable = mkEnableOption "tmux"; };
    config = mkIf cfg.enable {
        programs.tmux = {
            enable = true;

            sensibleOnTop = false;

            prefix = "C-s";

            extraConfig = extraConfig;
        };
    };
}
