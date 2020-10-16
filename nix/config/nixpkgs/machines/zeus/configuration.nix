{ config, lib, pkgs, ... }:

with lib;
let
  username = "dejanr";
  hostName = "zeus";
  nvidia_x11 = pkgs.linuxPackages.nvidia_x11;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../roles/common.nix
    ../../roles/shells/bash
    ../../roles/fonts.nix
    ../../roles/desktop.nix
    ../../roles/i3.nix
    ../../roles/services.nix
    ../../roles/virtualisation.nix
  ];

  networking = {
    hostId = "8425e349";
    hostName = "${hostName}";
  };

  services = {
    unifi.enable = true;
    unifi.openPorts = true;

    xserver = {
      enable = true;
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

  environment = {
    etc."X11/Xresources".text = ''
      Xft.dpi: 109
    '';
    systemPackages = [ nvidia_x11 ];
  };

  systemd.services.nvidia-control-devices = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = "${nvidia_x11.bin}/bin/nvidia-smi";
  };

  virtualisation.docker.enableNvidia = true;

  system.stateVersion = "20.03";
}
