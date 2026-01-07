{
  config,
  lib,
  pkgs,
  nixos,
  ...
}:

let
  cfg = config.home.stylix;
  theme = import (../themes + "/${cfg.theme}");
in
{
  options = {
    home.stylix = {
      enable = lib.mkEnableOption "Enable stylix theming";
    };
    home.stylix.theme = lib.mkOption {
      default = if (nixos.stylix.enable) then nixos.stylix.theme else "io";
      type = lib.types.enum (
        builtins.attrNames (lib.filterAttrs (name: type: type == "directory") (builtins.readDir ../themes))
      );
      description = "Theme for stylix to use for the user. A list of themes can be found in the `themes` directory.";
    };
  };

  config = lib.mkMerge [
    { stylix.overlays.enable = false; }

    (lib.mkIf cfg.enable {
      stylix.enable = true;
      home.file.".currenttheme".text = config.home.stylix.theme;
      stylix.autoEnable = false;
      stylix.polarity = theme.polarity;
      stylix.image = pkgs.fetchurl {
        url = theme.backgroundUrl;
        sha256 = theme.backgroundSha256;
      };
      stylix.base16Scheme = theme;

      stylix.fonts = {
        monospace = {
          name = "PragmataPro Mono";
          package = pkgs.pragmatapro;
        };
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };

        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        emoji = {
          name = "Twitter Color Emoji";
          package = pkgs.twitter-color-emoji;
        };
        sizes = {
          terminal = 14;
          applications = 14;
          popups = 14;
          desktop = 14;
        };
      };

      stylix.targets.gtk.enable = true;
      stylix.targets.kde.enable = true;
      stylix.targets.qt.enable = true;

      home.file = {
        ".config/qt5ct/colors/oomox-current.conf".source = config.lib.stylix.colors {
          template = builtins.readFile ./stylix/oomox-current.conf.mustache;
          extension = ".conf";
        };
        ".config/Trolltech.conf".source = config.lib.stylix.colors {
          template = builtins.readFile ./stylix/Trolltech.conf.mustache;
          extension = ".conf";
        };
        ".config/kdeglobals".source = config.lib.stylix.colors {
          template = builtins.readFile ./stylix/Trolltech.conf.mustache;
          extension = "";
        };
      };
      home.packages = with pkgs; [
        kdePackages.breeze
        kdePackages.breeze-icons
        nerd-fonts.fira-code
        fira-sans
        twitter-color-emoji
      ];

      fonts.fontconfig.defaultFonts = {
        monospace = [ config.stylix.fonts.monospace.name ];
        sansSerif = [ config.stylix.fonts.sansSerif.name ];
        serif = [ config.stylix.fonts.serif.name ];
      };
    })
  ];
}
