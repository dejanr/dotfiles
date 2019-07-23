{ config, lib, pkgs, ... }:

# GPD Pocket 2

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot = {
    initrd.availableKernelModules = [ "xhci_pci" "usb_storage" "usbhid" "sd_mod" "sdhci_pci" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];
    kernelParams = [
      "quiet" 
      "loglevel=3" 
      "fbcon=rotate:1"
      "vga=current" # quiet boot
    ];
    blacklistedKernelModules = [
    ];

    extraModprobeConfig = ''
    '';

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
      "kernel.nmi_watchdog" = 0;
    };

    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    supportedFilesystems = [ "zfs" ];
    zfs.enableUnstable = true;
    cleanTmpDir = true;
  };


  hardware = {
    cpu = {
      amd.updateMicrocode = true;
    };

    opengl = {
      enable =true;
      driSupport = true;
      driSupport32Bit = true;
    };

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];

    enableRedistributableFirmware = true;
  };

  fileSystems."/" =
    { device = "zpool/root/nixos";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/BB5B-730A";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/1bcf70c9-0def-4d4d-9540-e113a96f5730"; }
    ];

  nix.maxJobs = lib.mkDefault 4;
}
