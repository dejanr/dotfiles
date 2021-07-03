{ config, lib, pkgs, ... }:

with lib;
let
  username = "dejanr";
  hostName = "omega";
  nvidia_x11 = pkgs.linuxPackages.nvidia_x11;
in
  {
    imports = [
      ./hardware-configuration.nix
      ../../roles/common.nix
      ../../roles/hosts.nix
      ../../roles/shells/bash
      ../../roles/fonts.nix
      ../../roles/desktop.nix
      ../../roles/multimedia.nix
      ../../roles/i3.nix
      ../../roles/services.nix
      ../../roles/development.nix
      #../../roles/games.nix
      #../../roles/games/valheim.nix
    ];

    networking = {
      hostId = "8425e349";
      hostName = "${hostName}";
    };

    services = {
      xserver = {
        enable = true;
        useGlamor = true;
        videoDrivers = [ "nvidia" ];

        displayManager = {
          xserverArgs = [ "-dpi 109" ];
        };
      };

      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "ondemand";
          SCHED_POWERSAVE_ON_AC = 0;
          SCHED_POWERSAVE_ON_BAT = 1;
          ENERGY_PERF_POLICY_ON_AC = "performance";
          ENERGY_PERF_POLICY_ON_BAT = "powersave";
          PCIE_ASPM_ON_AC = "performance";
          PCIE_ASPM_ON_BAT = "powersave";
          WIFI_PWR_ON_AC = 1;
          WIFI_PWR_ON_BAT = 5;
          RUNTIME_PM_ON_AC = "on";
          RUNTIME_PM_ON_BAT = "auto";
          USB_BLACKLIST_WWAN = 1;
          SOUND_POWER_SAVE_ON_BAT = 0;
          USB_AUTOSUSPEND = 0;
          CONTROL_USB_AUTOSUSPEND = "off";
          DEVICES_TO_DISABLE_ON_STARTUP = "";
        };
      };
    };

    environment = {
      etc."X11/Xresources".text = ''
        Xft.dpi: 109
      '';
      systemPackages = [ nvidia_x11 ];
    };

    virtualisation.docker.enableNvidia = true;

    system.stateVersion = "20.09";
  }
