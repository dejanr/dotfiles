{ config, pkgs, lib, writeTextFile, colors, ... }:

with lib;

let
  stdenv = pkgs.stdenv;
  cfg = config.modules.ghostty;
in
{
  options.modules.ghostty = {
    enable = mkEnableOption "ghostty";
  };

  config = mkIf cfg.enable {
    fonts.fontconfig.enable = true;

    home.packages = [
      pkgs.ghostty
      pkgs.pragmatapro
    ];

    home.file."gtk.css".target = ".config/gtk-4.0/gtk.css";
    home.file."gtk.css".text = ''
      .background {
        margin: 0;
        padding: 0;
        box-shadow: 0 0 0 0;
      }
    '';

    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;

      package = if stdenv.isDarwin then null else pkgs.ghostty;
      installBatSyntax = lib.mkIf pkgs.stdenv.targetPlatform.isDarwin false; # Fix in master

      settings = {
        shell-integration = "zsh";
        shell-integration-features = [ "no-sudo" "no-cursor" "no-title" ];
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
        theme = "nightfox";
        confirm-close-surface = false;
        auto-update = "off";
        resize-overlay = "never";
      };
      themes = {
        nightfox = {
          palette = [
            "0=#393b44"
            "1=#c94f6d"
            "2=#81b29a"
            "3=#dbc074"
            "4=#719cd6"
            "5=#9d79d6"
            "6=#63cdcf"
            "7=#dfdfe0"
            "8=#575860"
            "9=#d16983"
            "10=#8ebaa4"
            "11=#e0c989"
            "12=#86abdc"
            "13=#baa1e2"
            "14=#7ad5d6"
            "15=#e4e4e5"
            "16=#f4a261"
          ];

          background = "#1c1c1c";
          foreground = "#cdcecf";
          selection-background = "#2b3b51";
          selection-foreground = "#cdcecf";
          cursor-color = "#cdcecf";
        };
      };
    };
  };
}
