{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.nixos.roles.i3;
  gtk2-theme = import ../../../utils/gtk2Theme.nix {
    theme = {
      package = pkgs.arc-theme;
      name = "Materia";
    };
    icons = {
      package = pkgs.arc-icon-theme;
      name = "Materia";
    };
  };
in
{
  imports = [ gtk2-theme ];

  options.modules.nixos.roles.i3 = {
    enable = mkEnableOption "i3 window manager system integration";
  };

  config = mkIf cfg.enable {

    xdg.portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-termfilechooser
      ];
      xdgOpenUsePortal = true;
      config.common = {
        default = "*";
        "org.freedesktop.impl.portal.ScreenCast" = "gtk";
        "org.freedesktop.impl.portal.RemoteDesktop" = "gtk";
      };
    };

    # Compositor for vsync, no tearing, and better rendering
    services.picom = {
      enable = true;
      backend = "glx";
      vSync = true;
      settings = {
        use-damage = true;
        # Disable effects for speed
        shadow = false;
        fading = false;
        blur.method = "none";
      };
    };

    environment.systemPackages = with pkgs; [
      wm-lock
      wm-wallpaper
      wm-workspace

      rofi # for app launcher
      rofi-menugen # Generates menu based applications using rofi
      feh # for background image
      polybar # status bar
      xdotool # inspect window title
      util-macros
      xcursorgen
      dex
      xcursor-themes
      xrdb
      xsetroot
      xbacklight
      sound-theme-freedesktop
      dunst # notifications
      i3minator # i3 project manager
      i3-config # custom i3 config from overlay
      i3blocks
      i3lock-fancy
      xscreensaver # screensaver
      thunar # file amanger
      thunar-volman
      thunar-archive-plugin
      xfce4-screenshooter
      ristretto # A fast and lightweight picture-viewer for the Xfce desktop environment
      tumbler # A D-Bus thumbnailer service
      xfce4-icon-theme # Icons for Xfce
      xfconf # Simple client-server configuration storage and query system for Xfce
      vte
      gnome-themes-extra
      gnome-settings-daemon # makes DPI scaling, fonts and GTK settings come active.
      dconf
      gtk-engine-murrine
      lxappearance # configure theme

      libx11
      libxinerama
      xev
      xkill
      xmessage

      networkmanagerapplet # NetworkManager control applet for GNOME

      pragmatapro

      # theme
      arc-icon-theme
      arc-theme
      capitaine-cursors
      numix-icon-theme
      papirus-icon-theme
      arc-icon-theme

      # dejli
      dejli-audio
      dejli-gif
      dejli-screenshot
    ];

    services.libinput = {
      enable = true;
      mouse = {
        tapping = false;
      };
      touchpad = {
        tapping = false;
        disableWhileTyping = true;
        naturalScrolling = true;
        middleEmulation = true;
      };
    };

    services.displayManager = {
      defaultSession = "none+i3";
    };

    services.xserver = {
      enable = true;
      autorun = true;

      windowManager = {
        i3 = {
          enable = true;
          package = pkgs.i3;
          configFile = "${pkgs.i3-config}/config";

          extraSessionCommands = ''
            export XDG_CURRENT_DESKTOP=i3

            # Import X11 environment into systemd user session
            ${pkgs.systemd}/bin/systemctl --user import-environment DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP
            ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP

            ${pkgs.dex}/bin/dex --autostart --environment i3 &
            ${pkgs.wm-wallpaper}/bin/wm-wallpaper &
            ${pkgs.xrdb}/bin/xrdb -merge ~/.Xresources &
            ${pkgs.xrdb}/bin/xrdb -merge /etc/X11/Xresources &
            ${pkgs.dunst}/bin/dunst &
            ${pkgs.tailscale-systray}/bin/tailscale-systray &
            ${pkgs.networkmanager_dmenu}/bin/nm-applet &
            ${pkgs.dunst}/bin/nm-applet &
          '';
        };
      };

      desktopManager = {
        xterm.enable = false;
      };

      displayManager = {
        lightdm = {
          enable = true;
          greeters.gtk.theme.package = pkgs.arc-theme;
          greeters.gtk.theme.name = "Arc-Dark";
          greeters.gtk.iconTheme.name = "Arc";
          greeters.gtk.iconTheme.package = pkgs.arc-icon-theme;
          greeters.gtk.cursorTheme.name = "Capitaine Cursors - White";
          greeters.gtk.cursorTheme.package = pkgs.capitaine-cursors;

          background = pkgs.fetchurl {
            url = "https://w.wallhaven.cc/full/wq/wallhaven-wqery6.jpg";
            sha256 = "0d5416glma4l2sksxszddd6iqchng85j2gf9vc10y14g07cgayg0";
          };

          greeters.gtk.extraConfig = ''
            indicators = ~spacer
            font-name = PragmataPro 12
            xft-antialias=true
            xft-dpi=98
            xft-hintstyle=hintfull
            xft-rgba=none
          '';
        };
      };

      xkb.options = "terminate:ctrl_alt_bksp, ctrl:nocaps";
    };
  };
}
