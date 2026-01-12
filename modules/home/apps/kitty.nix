{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.apps.kitty;
  colors = config.lib.stylix.colors;
in
{
  options.modules.apps.kitty = {
    enable = mkEnableOption "kitty";

    fontSize = mkOption {
      type = types.str;
      default = "14.0";
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
      extraConfig = import ../gui/kitty/config.nix {
        inherit colors;

        fontSize = cfg.fontSize;
      };
    };
  };
}
