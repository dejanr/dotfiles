{ config, lib, pkgs, ... }:

with lib;

let
  username = "dejanr";
  hostName = "homelab";
in {
  imports = [
    ./hardware-configuration.nix
    ../../roles/common.nix
    ../../roles/fonts.nix
    ../../roles/multimedia.nix
    ../../roles/desktop.nix
    ../../roles/i3.nix
    ../../roles/keybase.nix
    ../../roles/development.nix
    ../../roles/services.nix
    ../../roles/electronics.nix
    ../../roles/games.nix
  ];

  nix.useSandbox = false;

  networking = {
    hostId = "8425e349";
    hostName = "${hostName}";
  };

  services = {
    unifi.enable = true;

    octoprint = {
      enable = true;
      port = 8000;
    };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      displayManager = {
        xserverArgs = [ "-dpi 109" ];
      };
    };

    tlp = {
      enable = true;
      extraConfig = ''
        CPU_SCALING_GOVERNOR_ON_AC=performance
        CPU_SCALING_GOVERNOR_ON_BAT=ondemand
        SCHED_POWERSAVE_ON_AC=0
        SCHED_POWERSAVE_ON_BAT=1
        ENERGY_PERF_POLICY_ON_AC=performance
        ENERGY_PERF_POLICY_ON_BAT=powersave
        PCIE_ASPM_ON_AC=performance
        PCIE_ASPM_ON_BAT=powersave
        WIFI_PWR_ON_AC=1
        WIFI_PWR_ON_BAT=5
        RUNTIME_PM_ON_AC=on
        RUNTIME_PM_ON_BAT=auto
        USB_BLACKLIST_WWAN=1
        SOUND_POWER_SAVE_ON_BAT=0
        USB_AUTOSUSPEND=0
        CONTROL_USB_AUTOSUSPEND="off"
        DEVICES_TO_DISABLE_ON_STARTUP=""
      '';
    };
  };

  users.users.octoprint.extraGroups = [ "dialout" ];

  environment = {
    etc."X11/Xresources".text = ''
      Xft.dpi: 109
    '';
  };

  system.stateVersion = "19.03";
}
