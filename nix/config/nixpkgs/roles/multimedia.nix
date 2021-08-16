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
    extraConfig = ''
      load-module module-udev-detect tsched=0
      load-module module-bluetooth-policy
      load-module module-bluetooth-discover
      load-module module-switch-on-connect

      ### Enable Echo/Noise-Cancellation
      load-module module-echo-cancel use_master_format=1 aec_method=webrtc aec_args="analog_gain_control=0 digital_gain_control=1" source_name=echoCancel_source sink_name=echoCancel_sink
      set-default-source echoCancel_source
      set-default-sink echoCancel_sink
    '';
    extraModules = [
      pkgs.pulseaudio-modules-bt
    ];

    daemon.config = {
      avoid-resampling = "yes";
      default-sample-rate = 48000;
    };

    support32Bit = true;
  };

  services.minidlna = {
    enable = true;
    mediaDirs = [ "/home/dejanr/downloads" ];
  };
}
