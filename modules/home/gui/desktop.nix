{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.desktop;

in
{
  options.modules.home.gui.desktop = {
    enable = mkEnableOption "desktop applications";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      acpi
      arandr
      axel
      blender
      caffeine-ng
      imv
      evince
      gimp
      krita
      grobi
      google-drive-ocamlfuse
      gtypist
      hfsprogs
      inkscape
      kazam
      kdePackages.kdenlive
      lm_sensors
      magic-wormhole
      mutt
      newsboat
      pciutils
      pcmanfm
      pidgin
      pidginPackages.pidgin-window-merge
      pidginPackages.purple-plugin-pack
      powertop
      printrun
      qalculate-gtk
      scrot
      signal-desktop
      ifwifi
      wpa_supplicant
      prusa-slicer
      st
      sxiv
      termite
      termite.terminfo
      tesseract
      telegram-desktop
      thunderbird
      transmission_4-gtk
      usbutils
      unrar
      update-resolv-conf
      weechat
      xclip
      xsel
      xsettingsd
      zathura
      rmview
      teams-for-linux
      qutebrowser

      # Themes
      arc-icon-theme
      arc-theme
      adwaita-icon-theme

      freecad
      qutebrowser
    ];
  };
}
