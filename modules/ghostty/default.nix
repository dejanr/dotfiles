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

    programs.ghostty = {
      enable = true;
      enableZshIntegration = true;

      package = if stdenv.isDarwin then null else pkgs.ghostty;
      installBatSyntax = lib.mkIf pkgs.stdenv.targetPlatform.isDarwin false; # Fix in master

      settings = {
        shell-integration-features = "no-sudo no-cursor no-title";
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
      };
    };
  };
}
