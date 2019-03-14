{ config, pkgs, ... }:

{
  fonts = {
    enableCoreFonts = true;
    enableFontDir = true;
    enableGhostscriptFonts = false;

    fonts = with pkgs; [
      pragmatapro
      font-awesome-ttf
      terminus_font
      ubuntu_font_family
      liberation_ttf
      freefont_ttf
      source-code-pro
      inconsolata
      vistafonts
      dejavu_fonts
      freefont_ttf
      unifont
      cm_unicode
      ipafont
      baekmuk-ttf
      source-sans-pro
      source-serif-pro
      hasklig
    ];

    fontconfig = {
      enable = true;
      dpi = 100;
      antialias = true;
      hinting = {
        autohint = false;
        enable = true;
      };

      subpixel.lcdfilter = "default";

      ultimate = {
        enable = true; 
      };

      defaultFonts = {
        serif = [ "PragmataPro" ];
        sansSerif = [ "PragmataPro" ];
        monospace = [ "PragmataPro Mono" ];
      };
    };
  };
}
