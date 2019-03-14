{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alsaLib
    alsaPlugins
    alsaUtils
    ardour
    audacity
    blueman
    calf
    ffmpeg
    handbrake
    jack2Full
    ladspaPlugins
    libdvdcss
    libdvdnav
    libdvdread
    mplayer
    pamixer # cli tools for pulseaudio
    paprefs
    pavucontrol # volume control
    puredata
    qjackctl
    vlc
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    extraConfig = ''
      [General]
      Enable=Source,Sink,Media,Socket
      [Policy]
      AutoEnable=true
    '';
  };

  hardware.pulseaudio = {
    enable = true;
    support32Bit = true;
    package = pkgs.pulseaudioFull;
    extraConfig = ''
      load-module module-bluetooth-policy
      load-module module-bluetooth-discover
      load-module module-switch-on-connect
    '';
  };
}
