{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.desktop;

  teamsForLinux = pkgs.teams-for-linux.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      ${pkgs.jq}/bin/jq '.desktopName = "teams-for-linux.desktop"' package.json > package.json.tmp
      mv package.json.tmp package.json
    '';
  });

in
{
  options.modules.home.gui.desktop = {
    enable = mkEnableOption "desktop applications";
  };

  config = mkIf cfg.enable {
    home.file.".Xresources".text = ''
      Xft.dpi: 98
      Xft.antialias: true
      Xft.hinting: true
      Xft.hintstyle: hintfull
      Xft.rgba: none
    '';

    xdg.configFile."picom/picom.conf".text = ''
      # Mesa 26's GLX/EGL paths black-screen GFX12 (RX 9000) GPUs.
      backend = "xrender";
    '';

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
      lm_sensors
      magic-wormhole
      mutt
      newsboat
      pciutils
      pcmanfm

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
      teamsForLinux

      # Themes
      arc-icon-theme
      arc-theme
      adwaita-icon-theme

      freecad

      # OBS with plugins
      (wrapOBS {
        plugins = [
          obs-studio-plugins.obs-vintage-filter
          obs-studio-plugins.obs-pipewire-audio-capture
          obs-studio-plugins.obs-gradient-source
          obs-studio-plugins.obs-freeze-filter
          obs-studio-plugins.obs-composite-blur
          obs-studio-plugins.obs-backgroundremoval
          obs-studio-plugins.obs-3d-effect
          obs-studio-plugins.input-overlay
        ];
      })
    ];
  };
}
