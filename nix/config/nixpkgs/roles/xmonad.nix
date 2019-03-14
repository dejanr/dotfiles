{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    rofi                         # for app launcher
    rofi-menugen                 # Generates menu based applications using rofi

    scrot
    trayer
    dunst                        # notifications
    compton                      # window transitions
    xautolock                    # suckless xautolock
    shutter                      # Screenshot and annotation tool
    scrot                        # screenshot
    feh                          # for background image

    xorg.xsetroot
    xorg.utilmacros
    xorg.xcursorgen
    xorg.xcursorthemes
    xorg.xrdb
    xorg.xsetroot
    xorg.xbacklight
    sound-theme-freedesktop

    arc-icon-theme
    arc-theme
    vanilla-dmz                  # cursor theme

    xlibs.libX11
    xlibs.libXinerama
    xlibs.xev
    xlibs.xkill
    xlibs.xmessage

    networkmanagerapplet         # NetworkManager control applet for GNOME
    networkmanager_openvpn       # NetworkManager's OpenVPN plugin

    haskellPackages.xmobar
    haskellPackages.taffybar

    xsettingsd # Provides settings to X11 applications via the XSETTINGS specification
    wmctrl # Command line tool to interact with an EWMH/NetWM compatible X Window Manager

    gnome3.adwaita-icon-theme
  ];

  services.xserver = {
    enable = true;
    layout = "us";

    windowManager.xmonad.enable = true;
    windowManager.xmonad.enableContribAndExtras = true;
    windowManager.default = "xmonad";

    #windowManager.i3.enable = true;
    #windowManager.default = "i3";

    desktopManager.default = "none";
    desktopManager.xterm.enable = false;

    displayManager = {
      slim = {
        enable = true;
        defaultUser = "dejanr";
        theme = pkgs.fetchurl {
          url = "https://github.com/edwtjo/nixos-black-theme/archive/v1.0.tar.gz";
          sha256 = "13bm7k3p6k7yq47nba08bn48cfv536k4ipnwwp1q1l2ydlp85r9d";
        };
      };

      sessionCommands = ''
        ${pkgs.xorg.xrdb}/bin/xrdb -DSOLARIZED_DARK -load ~/.Xresources
        ${pkgs.xorg.xrdb}/bin/xrdb -merge /etc/X11/Xresources
        ${pkgs.dunst}/bin/dunst &
        ${pkgs.compton}/bin/compton --config ~/.comptonrc -b &
        ${pkgs.xautolock}/bin/xautolock -time 15 -locker ~/.bin/lock &
        ${pkgs.xorg.xsetroot}/bin/xsetroot -cursor_name left_ptr &
        ${pkgs.xsettingsd}/bin/xsettingsd &
        ${pkgs.feh}/bin/feh --bg-fill /etc/nixos/wallpapers/black-low-poly.jpg &
        ${pkgs.networkmanagerapplet}/bin/nm-applet &
        ${pkgs.emacs}/bin/emacs --daemon &
      '';
    };
  };
}
