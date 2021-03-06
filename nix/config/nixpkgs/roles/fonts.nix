{ config, pkgs, ... }:

{
  fonts = {
    fonts = with pkgs; [
      corefonts
      pragmatapro
      font-awesome-ttf
      terminus_font
      ubuntu_font_family
      liberation_ttf
      freefont_ttf
      source-code-pro
      inconsolata
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
      antialias = true;
      hinting = {
        autohint = false;
        enable = true;
      };

      subpixel.lcdfilter = "default";

      defaultFonts = {
        serif = [ "PragmataPro" ];
        sansSerif = [ "PragmataPro" ];
        monospace = [ "PragmataPro Mono" ];
      };
    };
  };
}
