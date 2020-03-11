{ config, lib, pkgs, ... }:

with lib;

let
  username = "dejanr";
  hostName = "homelab";
in {
  imports = [
    ./hardware-configuration.nix
    ../../roles/common.nix
    ../../roles/shells/bash
    ../../roles/fonts.nix
    ../../roles/multimedia.nix
    ../../roles/desktop.nix
    ../../roles/i3.nix
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
    unifi.openPorts = true;

    xserver = {
      enable = true;
      videoDrivers = [ "nvidiaBeta" ];
      displayManager = {
        xserverArgs = [ "-dpi 109" ];
      };

      deviceSection = ''
          Driver "nvidia"
          VendorName "NVIDIA Corporation"
          BusID "PCI:1:0:0"
      '';

      screenSection = ''
        Option         "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
        Option         "AllowIndirectGLXProtocol" "off"
        Option         "TripleBuffer" "on"
      '';
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
  };

  system.stateVersion = "19.03";
}
