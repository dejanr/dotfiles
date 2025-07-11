{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.nixos.roles.desktop;

in {
  options.modules.nixos.roles.desktop = { enable = mkEnableOption "desktop system integration"; };

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

    environment.systemPackages = with pkgs; [
      gnupg
      keychain
      libnotify
      openvpn
      pinentry
      polkit
      samba
      xdg-utils
      xorg.xmodmap
    ];

    services.blueman.enable = true;

    programs._1password = { enable = true; };
    programs._1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "dejanr" ];
    };
  };
}
