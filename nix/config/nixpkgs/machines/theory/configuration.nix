{ config, lib, pkgs, ... }:

let
  username = "dejanr";
  hostName = "theory";
  fancontrol = import ./fancontrol.nix {};
in {
  imports =
    [
      ./hardware-configuration.nix
      ./throttled.nix
      ../../roles/common.nix
      ../../roles/shells/bash
      ../../roles/desktop.nix
      ../../roles/i3.nix
      ../../roles/autolock.nix
      ../../roles/multimedia.nix
      ../../roles/development.nix
      ../../roles/services.nix
      ../../roles/fonts.nix
      ../../roles/email-client.nix
      ../../roles/autolock.nix
   ];

  nix.useSandbox = false;

  networking = {
    hostName = "theory";
    hostId = "7392bf5d";
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "intel" ];

      synaptics.enable = false;

      libinput = {
        enable = true;
        disableWhileTyping = true;
        naturalScrolling = true;
        buttonMapping = "1 1 1";
      };

      extraConfig = ''
        Section "InputClass"
        Identifier     "Enable libinput for TrackPoint"
        MatchIsPointer "on"
        Driver         "libinput"
        EndSection
      '';

      deviceSection = ''
        Driver "intel"
        Option "TearFree" "true"
        Option "DRI" "3"
        Option "Backlight" "intel_backlight"
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
        USB_AUTOSUSPEND=0
        CONTROL_USB_AUTOSUSPEND="off"
        DEVICES_TO_DISABLE_ON_STARTUP=""
        RUNTIME_PM_DRIVER_BLACKLIST="nouveau"
      '';
    };
  };

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

  environment = {
    etc."X11/Xresources".text = ''
      Xft.dpi: 144
    '';
    etc."fancontrol".text = fancontrol;
    variables.GDK_SCALE = "2";
    variables.GDK_DPI_SCALE = "0.5";
    variables.QT_SCALE_FACTOR = "1";
    variables.QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  };

  programs.light.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";

  environment.systemPackages = with pkgs; [
    thinkfan
  ];

  system.stateVersion = "19.09";
}
