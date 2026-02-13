{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.nixos.roles.desktop;

in
{
  options.modules.nixos.roles.desktop = {
    enable = mkEnableOption "desktop system integration";

    fontconfig = {
      hinting = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Enable font hinting";
        };
        style = mkOption {
          type = types.enum [ "none" "slight" "medium" "full" ];
          default = "slight";
          description = "Font hinting style";
        };
      };
      subpixel = {
        rgba = mkOption {
          type = types.enum [ "none" "rgb" "bgr" "vrgb" "vbgr" ];
          default = "rgb";
          description = "Subpixel rendering order (use 'none' for OLED)";
        };
        lcdfilter = mkOption {
          type = types.enum [ "none" "default" "light" "legacy" ];
          default = "default";
          description = "LCD filter for subpixel rendering";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        baekmuk-ttf
        cm_unicode
        corefonts
        dejavu_fonts
        font-awesome
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
        ubuntu-classic
        unifont
        vista-fonts
      ];

      fontconfig = {
        enable = true;
        antialias = true;
        hinting = {
          autohint = false;
          enable = cfg.fontconfig.hinting.enable;
          style = cfg.fontconfig.hinting.style;
        };

        subpixel.lcdfilter = cfg.fontconfig.subpixel.lcdfilter;
        subpixel.rgba = cfg.fontconfig.subpixel.rgba;

        defaultFonts = {
          serif = [ "PragmataPro" ];
          sansSerif = [ "PragmataPro" ];
          monospace = [ "PragmataPro Mono" ];
        };
      };
    };

    environment.systemPackages = with pkgs; [
      gnupg
      keychain
      libnotify
      polkit
      samba
      xdg-utils
      xmodmap
      google-chrome
      openscad-unstable

      # dejli
      dejli-audio
      dejli-gif
      dejli-screenshot
    ];

    services.blueman.enable = true;
  };
}
