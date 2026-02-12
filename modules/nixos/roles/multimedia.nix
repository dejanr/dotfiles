{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.nixos.roles.multimedia;
  isAsahi = config.hardware.asahi.enable or false;

in
{
  options.modules.nixos.roles.multimedia = {
    enable = mkEnableOption "multimedia system integration";
  };

  config = mkIf cfg.enable {
    environment.systemPackages =
      with pkgs;
      [
        alsa-utils
        alsa-plugins
        sox
        audacity
        gphoto2
        gphoto2fs
        libgphoto2
        blueman
        calf
        slop
        ffmpeg-full
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
        darktable
        mpv
        strawberry
      ]
      ++ optionals (!isAsahi) [
        # gpu-screen-recorder needs NVENC/VAAPI - not available on Asahi
        gpu-screen-recorder
        gpu-screen-recorder-gtk
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

    # Non-Asahi audio setup (Asahi uses its own sound module)
    security.rtkit.enable = mkIf (!isAsahi) true;

    services.pipewire = mkIf (!isAsahi) {
      enable = true;
      wireplumber.enable = true;

      alsa.enable = false;
      pulse.enable = true;
      jack.enable = true;

      lowLatency = {
        enable = true;
        quantum = 256;
        rate = 48000;
      };
    };

    programs.noisetorch.enable = !isAsahi;

    # Configure ALSA to use PulseAudio/PipeWire (non-Asahi only)
    environment.etc."asound.conf" = mkIf (!isAsahi) {
      text = ''
        pcm_type.pulse {
          lib "${pkgs.alsa-plugins}/lib/alsa-lib/libasound_module_pcm_pulse.so"
        }
        ctl_type.pulse {
          lib "${pkgs.alsa-plugins}/lib/alsa-lib/libasound_module_ctl_pulse.so"
        }
        pcm.!default {
          type pulse
        }
        ctl.!default {
          type pulse
        }
      '';
    };
  };
}
