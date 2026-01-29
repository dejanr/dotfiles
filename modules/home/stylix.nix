{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home.stylix;
  theme = import (../themes + "/${cfg.theme}");
  isLinux = pkgs.stdenv.isLinux;
in
{
  options.home.stylix.theme = lib.mkOption {
    default = "io";
    type = lib.types.enum (
      builtins.attrNames (lib.filterAttrs (name: type: type == "directory") (builtins.readDir ../themes))
    );
    description = "Theme for stylix to use for the user. A list of themes can be found in the `themes` directory.";
  };

  config = {
    stylix.overlays.enable = false;
    stylix.enable = true;
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

    stylix.targets.gtk.enable = isLinux;
    stylix.targets.kde.enable = isLinux;
    stylix.targets.qt.enable = isLinux;

    # Remove box-shadow for cleaner borderless windows (e.g., Ghostty)
    stylix.targets.gtk.extraCss = lib.mkIf isLinux ''
      .background {
        margin: 0;
        padding: 0;
        box-shadow: 0 0 0 0;
      }
    '';

    home.file = lib.mkIf isLinux {
      ".currenttheme".text = config.home.stylix.theme;
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

    home.packages =
      with pkgs;
      [
        nerd-fonts.fira-code
        fira-sans
        twitter-color-emoji
      ]
      ++ lib.optionals isLinux [
        kdePackages.breeze
        kdePackages.breeze-icons
      ];

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ config.stylix.fonts.monospace.name ];
        sansSerif = [ config.stylix.fonts.sansSerif.name ];
        serif = [ config.stylix.fonts.serif.name ];
      };
      antialiasing = true;
    };
  };
}
