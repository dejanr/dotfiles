{ config, boot, lib, pkgs, modulesPath, ... }:

let
  hostName = "theory";
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./apple-silicon-support
  ];

  boot = {
    initrd.availableKernelModules = ["usb_storage" "sdhci_pci"];
    initrd.supportedFilesystems = [ ];
    initrd.kernelModules = [ ];

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
      "vm.max_map_count" = 16777216;
    };

    supportedFilesystems = [ ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = false;
    };

    tmp.cleanOnBoot = true;
  };

  time.hardwareClockInLocalTime = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/173035b7-060a-4f39-8d31-2dab13be081e";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/33F9-19E8";
      fsType = "vfat";
    };

  hardware = {
    asahi.peripheralFirmwareDirectory = ./firmware;
    asahi.useExperimentalGPUDriver = true;
  };

  networking = {
    useDHCP = lib.mkDefault true;
    hostId = "8425e349";
    hostName = "${hostName}";

    networkmanager.enable = true;
    interfaces.wlp1s0f0.useDHCP = lib.mkDefault true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
