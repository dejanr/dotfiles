{ config, lib, pkgs, ... }:

let
  gtk2-theme = import ../utils/gtk2Theme.nix {
    theme = {
      package = pkgs.materia-theme;
      name = "Materia";
    };
    icons = {
      package = pkgs.materia-theme;
      name = "Materia";
    };
  };
in
{
  imports = [
    gtk2-theme
  ];

  environment.systemPackages = with pkgs; [
    rofi # for app launcher
    rofi-menugen # Generates menu based applications using rofi
    feh # for background image
    scrot # screenshot
    shutter # Screenshot and annotation tool
    lxqt.screengrab # Crossplatform tool for fast making screenshots
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
    xfce.thunar_volman
    xfce.thunar-archive-plugin
    xfce.xfce4-screenshooter
    xfce.ristretto # A fast and lightweight picture-viewer for the Xfce desktop environment
    xfce.tumbler # A D-Bus thumbnailer service
    xfce.xfce4icontheme # Icons for Xfce
    xfce.xfconf # Simple client-server configuration storage and query system for Xfce
    gnome3.vte
    gnome3.gnome_themes_standard
    gnome3.gnome_settings_daemon # makes DPI scaling, fonts and GTK settings come active.
    gnome3.dconf
    gtk-engine-murrine
    lxappearance # configure theme
    vanilla-dmz # cursor theme

    xlibs.libX11
    xlibs.libXinerama
    xlibs.xev
    xlibs.xkill
    xlibs.xmessage

    networkmanagerapplet # NetworkManager control applet for GNOME
    networkmanager_openvpn # NetworkManager's OpenVPN plugin
  ];

  services.xserver = {
    enable = true;
    useGlamor = true;
    autorun = true;

    libinput = {
      enable = true;
      touchpad = {
        disableWhileTyping = true;
        naturalScrolling = true;
        middleEmulation = true;
      };
    };

    windowManager = {
      i3 = {
        enable = true;
        package = pkgs.i3-gaps;
        configFile = "${pkgs.i3-config}/config";

        extraSessionCommands = ''
          ${pkgs.wm-wallpaper}/bin/wm-wallpaper
          ${pkgs.xorg.xrdb}/bin/xrdb -merge ~/.Xresources
          ${pkgs.xorg.xrdb}/bin/xrdb -merge /etc/X11/Xresources
          ${pkgs.dunst}/bin/dunst &
          ${pkgs.networkmanager_dmenu}/bin/nm-applet &
          ${pkgs.dunst}/bin/nm-applet &
        '';
      };
    };

    desktopManager = {
      xterm.enable = false;
    };

    displayManager = {
      defaultSession = "none+i3";

      lightdm = {
        enable = true;
      };
    };

    xkbOptions = "terminate:ctrl_alt_bksp, ctrl:nocaps";
  };
}
