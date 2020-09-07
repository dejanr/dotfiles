# themes/fluorescence/default.nix --- a regal dracula-inspired theme

{ config, options, lib, pkgs, ... }:
with lib;
let cfg = config.modules;
in {
  options.modules.themes.fluorescence = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf cfg.themes.fluorescence.enable {
    modules.theme = {
      name = "fluorescence";
      version = "0.0.1";
      path = ./.;

      wallpaper = {
        filter.options = "-gaussian-blur 0x2 -modulate 70 -level 5%";
      };
    };

    services.xserver.displayManager.lightdm = {
      greeters.mini.extraConfig = ''
        text-color = "#ff79c6"
        password-background-color = "#1E2029"
        window-color = "#181a23"
        border-color = "#181a23"
      '';
    };

    fonts = {
      enableFontDir = true;

      fonts = with pkgs; [
        corefonts
        my.pragmatapro
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

    my.packages = with pkgs; [
      sxhkd
      my.ant-dracula
      paper-icon-theme # for rofi
    ];

    my.home = {
      home.file = mkMerge [
        (mkIf cfg.desktop.browsers.firefox.enable {
          ".mozilla/firefox/${cfg.desktop.browsers.firefox.profileName}.default/chrome/userChrome.css" =
            {
              source = ./firefox/userChrome.css;
            };
        })
      ];

      xdg.configFile = mkMerge [
        (mkIf config.services.xserver.enable {
          "xtheme/90-theme".source = ./Xresources;
          # GTK
          "gtk-3.0/settings.ini".text = ''
            [Settings]
            gtk-theme-name=Ant-Dracula
            gtk-icon-theme-name=Paper
            gtk-fallback-icon-theme=gnome
            gtk-application-prefer-dark-theme=true
            gtk-cursor-theme-name=Paper
            gtk-xft-hinting=1
            gtk-xft-hintstyle=hintfull
            gtk-xft-rgba=none
          '';
          # GTK2 global theme (widget and icon theme)
          "gtk-2.0/gtkrc".text = ''
            gtk-theme-name="Ant-Dracula"
            gtk-icon-theme-name="Paper-Mono-Dark"
            gtk-font-name="Sans 10"
          '';
          # QT4/5 global theme
          "Trolltech.conf".text = ''
            [Qt]
            style=Ant-Dracula
          '';
        })
        (mkIf cfg.desktop.bspwm.enable {
          "bspwm/rc.d/polybar".source = ./polybar/run.sh;
          "bspwm/rc.d/theme".source = ./bspwmrc;
        })
        (mkIf cfg.desktop.apps.rofi.enable {
          "rofi/theme" = {
            source = ./rofi;
            recursive = true;
          };
        })
        (mkIf (cfg.desktop.bspwm.enable) {
          "polybar" = {
            source = ./polybar;
            recursive = true;
          };
          "dunst/dunstrc".source = ./dunstrc;
        })
        (mkIf cfg.shell.tmux.enable { "tmux/theme".source = ./tmux.conf; })
        (mkIf cfg.desktop.term.termite.enable {
          "termite/config".source = ./termite.conf;
        })
      ];

      xdg.dataFile = mkMerge [
        (mkIf cfg.desktop.browsers.qutebrowser.enable {
          "qutebrowser/userstyles.css".source = let
            compiledStyles = with pkgs;
              runCommand "compileUserStyles" { buildInputs = [ sass ]; } ''
                mkdir "$out"
                for file in ${./userstyles/qutebrowser}/*.scss; do
                  scss --sourcemap=none \
                       --no-cache \
                       --style compressed \
                       --default-encoding utf-8 \
                       "$file" \
                       >>"$out/userstyles.css"
                done
              '';
          in "${compiledStyles}/userstyles.css";
        })
      ];
    };
  };
}
