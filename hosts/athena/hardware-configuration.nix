{ config, lib, pkgs, ... }:

# ASRock A300
# Ryzen 2400G

{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "lm92" ];
    kernelModules = [ "kvm-amd" "nct6775" "k10temp" "coretemp" ];
    kernelParams = [
      "quiet"
      "loglevel=3"
      "vga=current" # quiet boot
    ];
    blacklistedKernelModules = [
      "sp5100-tco"
    ];

    extraModprobeConfig = ''
      options k10temp force=1
      options amdgpu si_support=1
      options amdgpu cik_support=0
    '';

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
      "kernel.nmi_watchdog" = 0;
    };

    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    supportedFilesystems = [ "zfs" "exfat" ];
    zfs.enableUnstable = true;
    cleanTmpDir = true;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  hardware = {
    bluetooth.enable = true;

    cpu = {
      amd.updateMicrocode = true;
    };

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
        intel-media-driver # only available starting nixos-19.03 or the current nixos-unstable
      ];
    };

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];

    enableRedistributableFirmware = true;
  };

  ## SSDs
  services.fstrim.enable = true;

  ## CPU
  nix.maxJobs = lib.mkDefault 8;
  services.tlp = {
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

  ## GPU
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
  };

  services.xserver.xkbOptions = "compose:ralt";

  ## FANS
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

  environment.etc."fancontrol".text = ''
    INTERVAL=10
    DEVPATH=hwmon0=devices/platform/nct6775.656 hwmon1=devices/pci0000:00/0000:00:18.3
    DEVNAME=hwmon0=nct6793 hwmon1=k10temp
    FCTEMPS=hwmon0/pwm2=hwmon1/temp1_input
    FCFANS= hwmon0/pwm2=hwmon0/fan2_input
    MINTEMP=hwmon0/pwm2=50
    MINPWM=50
    MINSTART=hwmon0/pwm2=80
    MINSTOP=hwmon0/pwm2=50
    MAXTEMP=hwmon0/pwm2=80
    MAXPWM=240
  '';

  ### Harddrives
  fileSystems."/" =
    {
      device = "zpool/root";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
    };

  swapDevices = [];
}
