{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rofi                         # for app launcher
    rofi-menugen                 # Generates menu based applications using rofi
    feh                          # for background image
    scrot                        # screenshot
    shutter                      # Screenshot and annotation tool
    lxqt.screengrab              # Crossplatform tool for fast making screenshots
    polybar                      # status bar
    xdotool                      # inspect window title
    xorg.utilmacros
    xorg.xcursorgen
    xorg.xcursorthemes
    xorg.xrdb
    xorg.xsetroot
    xorg.xbacklight
    sound-theme-freedesktop
    dunst                        # notifications
    compton                      # window transitions
    i3minator                    # i3 project manager
    i3blocks
    i3lock-fancy
    xscreensaver                 # screensaver
    xfce.thunar                  # file amanger
    xfce.thunar_volman
    xfce.thunar-archive-plugin
    xfce.xfce4-screenshooter
    xfce.gvfs                    # virtual filesystem
    xfce.ristretto               # A fast and lightweight picture-viewer for the Xfce desktop environment
    xfce.tumbler                 # A D-Bus thumbnailer service
    xfce.xfce4icontheme          # Icons for Xfce
    xfce.xfconf                  # Simple client-server configuration storage and query system for Xfce
    gnome3.vte
    gnome3.gnome_keyring
    gnome3.gnome_themes_standard # arc theme
    gnome3.gnome_settings_daemon # makes DPI scaling, fonts and GTK settings come active.
    gnome3.dconf
    arc-icon-theme
    arc-theme
    gtk-engine-murrine           # arc theme
    lxappearance                 # configure theme
    vanilla-dmz                  # cursor theme

    xlibs.libX11
    xlibs.libXinerama
    xlibs.xev
    xlibs.xkill
    xlibs.xmessage

    networkmanagerapplet         # NetworkManager control applet for GNOME
    networkmanager_openvpn       # NetworkManager's OpenVPN plugin
  ];

  services.xserver = {
    enable = true;
    dpi = 144;
    useGlamor = true;
    autorun = true;

    startDbusSession = true;

    libinput = {
      enable = true;
      disableWhileTyping = true;
      naturalScrolling = true;
    };

    windowManager = {
      i3 = {
        enable = true;
        package = pkgs.i3-gaps;
      };

      default = "i3";
    };

    desktopManager = {
      default = "pantheon";
      xterm.enable = false;
    };

    displayManager = {
      sessionCommands = with pkgs; lib.mkAfter
      ''
        ${pkgs.feh}/bin/feh --bg-fill /etc/nixos/wallpapers/bluemist.jpg &
        ${pkgs.xorg.xrdb}/bin/xrdb -merge ~/.Xresources
        ${pkgs.xorg.xrdb}/bin/xrdb -merge /etc/X11/Xresources
      '';
    };

		xkbOptions = "terminate:ctrl_alt_bksp, ctrl:nocaps";
  };

  # Enable secrets store.
  security.pam.services.lightdm.enableGnomeKeyring = true;
}
