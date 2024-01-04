{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.modules.kitty;
in
{
  options.modules.kitty = { enable = mkEnableOption "kitty"; };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages = [
        pkgs.pragmatapro
    ];

    programs.kitty = {
        enable = true;
        extraConfig = builtins.readFile ./kitty;
    };
  };
}
