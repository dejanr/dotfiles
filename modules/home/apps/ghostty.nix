{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  stdenv = pkgs.stdenv;
  cfg = config.modules.apps.ghostty;
  colors = config.lib.stylix.colors;
in
{
  options.modules.apps.ghostty = {
    enable = mkEnableOption "ghostty";
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages = [
      pkgs.ghostty
      pkgs.pragmatapro
    ];

    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;

      package = if stdenv.isDarwin then null else pkgs.ghostty;
      installBatSyntax = lib.mkIf pkgs.stdenv.targetPlatform.isDarwin false; # Fix in master

      settings = {
        shell-integration = "zsh";
        shell-integration-features = [
          "no-sudo"
          "no-cursor"
          "no-title"
        ];
        font-family = "PragmataPro Mono Regular";
        font-family-bold = "PragmataPro Mono Bold";
        font-family-italic = "PragmataPro Mono Italic";
        font-family-bold-italic = "PragmataPro Mono Bold Italic";
        font-thicken = false;
        font-size = 14;
        font-feature = [
          "calt"
          "liga"
        ];
        window-decoration = false;
        macos-titlebar-style = "hidden";

        cursor-style-blink = false;
        theme = "stylix";
        confirm-close-surface = false;
        auto-update = "off";
        resize-overlay = "never";
        term = "xterm-ghostty";
        window-vsync = true;
      };
      themes = {
        stylix = {
          palette = [
            "0=#${colors.base00}"
            "1=#${colors.base08}"
            "2=#${colors.base0B}"
            "3=#${colors.base0A}"
            "4=#${colors.base0D}"
            "5=#${colors.base0E}"
            "6=#${colors.base0C}"
            "7=#${colors.base05}"
            "8=#${colors.base03}"
            "9=#${colors.base08}"
            "10=#${colors.base0B}"
            "11=#${colors.base0A}"
            "12=#${colors.base0D}"
            "13=#${colors.base0E}"
            "14=#${colors.base0C}"
            "15=#${colors.base07}"
            "16=#${colors.base09}"
          ];

          background = "#${colors.base00}";
          foreground = "#${colors.base05}";
          selection-background = "#${colors.base02}";
          selection-foreground = "#${colors.base05}";
          cursor-color = "#${colors.base05}";
        };
      };
    };
  };
}
