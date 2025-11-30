{
  config,
  boot,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  hostName = "zima";
  kernelPackages = pkgs.linuxPackages_latest;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [ "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "sdhci_pci" ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    kernelPackages = kernelPackages;

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
    };

    kernelParams = [
      "quiet"
      "splash"
      "hugepagesz=1GB"
      "loglevel=3"
    ];

    blacklistedKernelModules = [ ];

    extraModprobeConfig = '''';

    initrd.supportedFilesystems = [ ];

    supportedFilesystems = [ ];

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 10;
      efi.canTouchEfiVariables = true;
    };

    tmp.cleanOnBoot = true;
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/3b17614d-6d06-4585-a3f6-86a80c9844ac";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F365-3F80";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/d84cccd7-dfbc-485f-b097-0e6234f44675";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/c52ba68b-e5be-41dc-a7d7-9aed4ee35be7"; }
    ];

  hardware = {
    cpu = {
      intel.updateMicrocode = true;
    };

    firmware = [
      pkgs.linux-firmware
    ];

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
  };

  networking = {
    hostName = "${hostName}";
    nameservers = ["8.8.8.8"];
    useDHCP = lib.mkDefault false;

    networkmanager.enable = false;
    firewall.enable = true;

    interfaces.enp2s0.useDHCP = lib.mkDefault true;
    interfaces.enp3s0.useDHCP = lib.mkDefault true;
  };

  nix.settings.max-jobs = lib.mkDefault 4;
}
