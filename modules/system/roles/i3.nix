{ config, lib, pkgs, ... }:

let
  gtk2-theme = import ../utils/gtk2Theme.nix {
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

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    xdgOpenUsePortal = true;
    config.common.default = "*";
  };

  environment.systemPackages = with pkgs; [
    wm-lock
    wm-wallpaper

    rofi # for app launcher
    rofi-menugen # Generates menu based applications using rofi
    feh # for background image
    polybar # status bar
    xdotool # inspect window title
    xorg.utilmacros
    xorg.xcursorgen
    xorg.xcursorthemes
    xorg.xrdb
    xorg.xsetroot
    xorg.xbacklight
    sound-theme-freedesktop
    dunst # notifications
    i3minator # i3 project manager
    i3-config # custom i3 config from overlay
    i3blocks
    i3lock-fancy
    xscreensaver # screensaver
    xfce.thunar # file amanger
    xfce.thunar-volman
    xfce.thunar-archive-plugin
    xfce.xfce4-screenshooter
    xfce.ristretto # A fast and lightweight picture-viewer for the Xfce desktop environment
    xfce.tumbler # A D-Bus thumbnailer service
    xfce.xfce4-icon-theme # Icons for Xfce
    xfce.xfconf # Simple client-server configuration storage and query system for Xfce
    vte
    gnome-themes-extra
    gnome-settings-daemon # makes DPI scaling, fonts and GTK settings come active.
    dconf
    gtk-engine-murrine
    lxappearance # configure theme

    xorg.libX11
    xorg.libXinerama
    xorg.xev
    xorg.xkill
    xorg.xmessage

    networkmanagerapplet # NetworkManager control applet for GNOME
    networkmanager-openvpn # NetworkManager's OpenVPN plugin

    pragmatapro

    # theme
    arc-icon-theme
    arc-theme
    capitaine-cursors
    numix-icon-theme
    papirus-icon-theme
    arc-icon-theme

    screenshot
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
        package = pkgs.i3-gaps;
        configFile = "${pkgs.i3-config}/config";

        extraSessionCommands = ''
          ${pkgs.wm-wallpaper}/bin/wm-wallpaper &
          ${pkgs.xorg.xrdb}/bin/xrdb -merge ~/.Xresources &
          ${pkgs.xorg.xrdb}/bin/xrdb -merge /etc/X11/Xresources &
          ${pkgs.dunst}/bin/dunst &
          ${pkgs.tailscale-systray}/bin/tailscale-systray &
          ${pkgs.networkmanager_dmenu}/bin/nm-applet &
          ${pkgs.dunst}/bin/nm-applet &
        '';
      };
    };

    desktopManager = { xterm.enable = false; };

    displayManager = {
      lightdm = {
        enable = true;
        greeters.gtk.theme.package = pkgs.arc-theme;
        greeters.gtk.theme.name = "Arc-Dark";
        greeters.gtk.iconTheme.name = "Arc";
        greeters.gtk.cursorTheme.name = "Capitaine Cursors - White";

        background = pkgs.fetchurl {
          url = "https://w.wallhaven.cc/full/wq/wallhaven-wqery6.jpg";
          sha256 = "0d5416glma4l2sksxszddd6iqchng85j2gf9vc10y14g07cgayg0";
        };

        greeters.gtk.extraConfig = ''
          indicators = ~spacer
          font-name = PragmataPro 12
          xft-antialias=true
          xft-dpi=109
          xft-hintstyle=hintslight
          xft-rgba=rgb
        '';
      };
    };

    xkb.options = "terminate:ctrl_alt_bksp, ctrl:nocaps";
  };
}
