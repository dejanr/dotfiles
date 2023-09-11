{ config, pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      baekmuk-ttf
      cm_unicode
      corefonts
      dejavu_fonts
      font-awesome
      freefont_ttf
      freefont_ttf
      hasklig
      inconsolata
      ipafont
      liberation_ttf
      pragmatapro
      source-code-pro
      source-sans-pro
      source-serif-pro
      terminus_font
      ubuntu_font_family
      unifont
      vistafonts
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
