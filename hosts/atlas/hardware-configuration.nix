{ config, boot, lib, pkgs, modulesPath, ... }:

# IOMMU Group 42:
# 	35:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP106 [GeForce GTX 1060 6GB] [10de:1c03] (rev a1)
# 	35:00.1 Audio device [0403]: NVIDIA Corporation GP106 High Definition Audio Controller [10de:10f1] (rev a1)

let
  hostName = "atlas";
  kernelPackages = pkgs.linuxPackages_latest;
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

    kernelModules = [ "kvm-amd" "nct6775" "k10temp" "coretemp" "i2c-dev" ];
    blacklistedKernelModules = [ "sp5100-tco" ];

    kernelPackages = kernelPackages;

    extraModulePackages = [ ];

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
    };

    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "iommu=1"
      "quiet"
      "splash"
      "hugepagesz=1GB"
      "loglevel=3"
    ];

    extraModprobeConfig = ''
      options k10temp force=1
      options amdgpu si_support=1
      options amdgpu cik_support=1
    '';

    initrd.supportedFilesystems = [ ];
    supportedFilesystems = [ ];

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 19;
      efi.canTouchEfiVariables = true;
    };

    tmp.cleanOnBoot = true;
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/2fc0d291-ddf1-44d3-8454-cb5249de58e7";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/A5A3-834C";
      fsType = "vfat";
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/3f310f54-2430-483f-be2b-d86895de7875"; }];

  # fileSystems."/mnt/synology/inbox" = {
  #   device = "192.168.1.168:/volume1/inbox";
  #   fsType = "nfs";
  # };

  # fileSystems."/mnt/synology/storage" = {
  #   device = "192.168.1.168:/volume1/storage";
  #   fsType = "nfs";
  # };

  hardware = {
    cpu = { amd.updateMicrocode = true; };

    opengl = {
      extraPackages = with pkgs; [
      ];
    };

    firmware = [ pkgs.firmwareLinuxNonfree ];

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
  };

  networking = {
    useDHCP = lib.mkDefault true;
    hostId = "8425e349";
    hostName = "${hostName}";
  };

  services = {
    hardware.bolt.enable =
      true; # Userspace daemon to enable security levels for Thunderbolt 3 on GNU/Linux.

    udev.extraRules = ''
      # Always authorize thunderbolt connections when they are plugged in.
      ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
    '';

    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];

      displayManager = { xserverArgs = [ "-dpi 109" ]; };

      screenSection = ''
        Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
        Option         "AllowIndirectGLXProtocol" "off"
        Option         "TripleBuffer" "on"
      '';

      deviceSection = ''
        Option  "DRI" "3"
        Option  "TearFree" "true"
      '';
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
  };

  environment.systemPackages = with pkgs; [
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  nix.settings.max-jobs = lib.mkDefault 8;
}
