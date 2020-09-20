{ config, lib, pkgs, ... }:
let
  hostName = "rhea";
  fancontrol = import ./fancontrol.nix {};
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../roles/common.nix
      ../../roles/shells/bash
      ../../roles/fonts.nix
      ../../roles/desktop.nix
      ../../roles/i3.nix
      ../../roles/services.nix
      ../../roles/virtualization.nix
    ];

  nix.useSandbox = true;

  networking = {
    hostName = hostName;
    hostId = "8425e349";
  };

  services = {
    xserver = {
      enable = true;
      useGlamor = true;
      videoDrivers = [ "amdgpu" ];

      deviceSection = ''
        Option "TearFree" "true"
        Option "DRI" "3"
      '';

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

  fonts.fontconfig.dpi = 109;

  programs.light.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";

  systemd.services.fancontrol = {
    description = "Start fancontrol";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.lm_sensors}/sbin/fancontrol";
    };
  };

  systemd.services.fancontrolRestart = {
    description = "Restart fancontrol on resume";
    wantedBy = [ "suspend.target" ];
    after = [ "suspend.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.systemd}/bin/systemctl --no-block restart fancontrol";
    };
  };

  environment.etc."fancontrol".text = fancontrol;

  system.stateVersion = "19.09";
}
