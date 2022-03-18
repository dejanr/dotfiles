{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
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
    pavucontrol
    puredata
    qjackctl
    vlc
    darktable # Virtual lighttable and darkroom for photographers
    helvum # A GTK patchbay for pipewire
    carla
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.minidlna = {
    enable = true;
    mediaDirs = [ "/home/dejanr/downloads" ];
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
    ];
    gtkUsePortal = true;
  };
}
