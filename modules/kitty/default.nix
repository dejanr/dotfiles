{ config, pkgs, lib, writeTextFile, colors, ... }:

with lib;

let
  cfg = config.modules.kitty;
in
{
    options.modules.kitty = {
        enable = mkEnableOption "kitty";

        fontSize = mkOption {
            type = types.str;
            default = "18.0";
            description = ''
                Custom font size.
            '';
            example = "18.0";
        };
    };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages = [
        pkgs.kitty
        pkgs.pragmatapro
    ];

    programs.kitty = {
        enable = true;
        extraConfig = import ./config.nix {
            inherit colors;

            fontSize = cfg.fontSize;
        };
    };
  };
}
