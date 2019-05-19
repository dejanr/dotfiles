{ config, lib, pkgs, ... }:

# Asrock A300
# Ryzen 2400G

{
  imports =
    [ <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
    ];

  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "kvm-amd" ];
    kernelParams = [
    ];
    blacklistedKernelModules = [
      "sp5100-tco"
    ];

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

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/D951-D4DC";
      fsType = "vfat";
    };

  fileSystems."/" =
    { device = "zpool/root/nixos";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "zpool/home";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/0ea6483b-2e05-4992-9612-4265246dc693"; }
    ];

  nix.maxJobs = lib.mkDefault 8;
}
