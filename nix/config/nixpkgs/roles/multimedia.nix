{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alsaLib
    alsaPlugins
    alsaUtils
    audacity
    gphoto2 # A ready to use set of digital camera software applications
    gphoto2fs # Fuse FS to mount a digital camera
    libgphoto2 # A library for accessing digital cameras
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
    lxqt.pavucontrol-qt
    puredata
    qjackctl
    vlc
    darktable # Virtual lighttable and darkroom for photographers
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  hardware.pulseaudio = {
    enable = true;

    support32Bit = true;
  };

  services.minidlna = {
    enable = true;
    mediaDirs = [ "/home/dejanr/downloads" ];
  };
}
