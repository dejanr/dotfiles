{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alsa-utils
    audacity
    gphoto2 # A ready to use set of digital camera software applications
    gphoto2fs # Fuse FS to mount a digital camera
    libgphoto2 # A library for accessing digital cameras
    blueman
    calf
    hacksaw # Lightweight selection tool for usage in screenshot scripts etc
    slop # Queries a selection from the user and prints to stdout
    (ffmpeg-full.override {
     withXcb = true;
    })
    gpu-screen-recorder # screen recorder that has minimal impact on system performance by recording your monitor using the GPU only
    gpu-screen-recorder-gtk # GTK for screen recorder that has minimal impact on system performance by recording your monitor using the GPU only
    handbrake
    jack2
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
    # helvum # A GTK patchbay for pipewire
    # carla
    yt-dlp # Command-line tool to download videos from YouTube.com and other sites (youtube-dl fork)
    mpv
    strawberry # Music player and music collection organizer
    pulseaudioFull
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.minidlna = {
    enable = true;
    settings = {
      media_Dir = [ "/home/dejanr/downloads" ];
    };
  };

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    wireplumber.enable = true;

    alsa.enable = false;
    pulse.enable = true;
    jack.enable = true;

    extraConfig.pipewire = {
      "10-clock-rate" = {
        "context.properties" = {
          "default.clock.rate" = 44100;
          "default.clock.allowed-rates" = [ 44100 48000 96000 ];
          "default.clock.quantum" = 32;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 1024;
        };
      };
    };
  };
}
