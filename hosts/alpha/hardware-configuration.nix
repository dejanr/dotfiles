{ config, boot, lib, pkgs, modulesPath, ... }:

let
  hostName = "alpha";
  kernelPackages = pkgs.linuxPackages_latest;
  deviceIDs = [
    "02:00.0" # Ethernet controller: Intel Corporation I210 Gigabit Network Connection (rev 03)
    "05:00.0" # Ethernet controller: Intel Corporation I210 Gigabit Network Connection (rev 03)
  ];
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    initrd.kernelModules = [ ];

    kernelModules = [
      "kvm-intel"
      "tun"
      "virtio"
      "coretemp"
      "i2c-dev"
      "k10temp"
      "vfio"
      "vfio_pci"
      "vfio_iommu_type1"
      "vfio_virqfd"
      "virtio"
    ];

    kernelPackages = kernelPackages;

    extraModulePackages = [ ];

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
      "vm.max_map_count" = 16777216;
    };

    kernelParams = [
      "quiet"
      "splash"
      "hugepagesz=1GB"
      "loglevel=3"
      ("vfio-pci.ids=" + lib.concatStringsSep "," deviceIDs)
    ];

    blacklistedKernelModules = [ ];

    extraModprobeConfig = '''';

    initrd.supportedFilesystems = [ ];

    supportedFilesystems = [ ];

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 19;
      efi.canTouchEfiVariables = true;
    };

    tmp.cleanOnBoot = true;
  };

  time.hardwareClockInLocalTime = true;

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/6c39fcc8-a117-4378-a197-68481b09f37a";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/5C82-BCBF";
      fsType = "vfat";
    };

  swapDevices = [
    { device = "/dev/disk/by-uuid/97defdf0-f29d-4920-a4fd-737b0460fb22"; }
  ];

  hardware = {
    cpu = {
      intel.updateMicrocode = true;
    };

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
  };

  networking = {
    useDHCP = lib.mkDefault true;
    hostName = "${hostName}";
  };

  nix.settings.max-jobs = lib.mkDefault 4;
}
