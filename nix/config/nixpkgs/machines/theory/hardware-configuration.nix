{ config, lib, pkgs, ... }:

{
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

    initrd = {
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
      luks.devices.decrypted-hdd = {
        device = "/dev/disk/by-id/nvme-WDC_PC_SN720_SDAQNTW-512G-1001_184791804261-part2";
        keyFile = "/keyfile.bin";
      };
    };

    kernelModules = [
      "acpi_call"
      "kvm-intel"
      "i915"
    ];

    blacklistedKernelModules = [
      "fbcon"
      "bbswitch"
      "nvidia"
      "nvidia-drm"
      "nvidia-uvm"
      "nvidia-modesetting"
      "nouveau"
    ];

    kernelParams = [
      "i915.enable_fbc=1"
      "i915.enable_psr=0"
    ];

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
    };

    supportedFilesystems = [ "zfs" ];
    cleanTmpDir = true;

    loader = {
      efi.efiSysMountPoint = "/efi";

      grub = {
      device = "nodev";
      efiSupport = true;
      extraInitrd = "/boot/initrd.keys.gz";
      enableCryptodisk = true;
      zfsSupport = true;
        efiInstallAsRemovable = true;
      };
    };
  };

  fileSystems."/" =
    { device = "zroot/root";
      fsType = "zfs";
    };

  fileSystems."/efi" =
    { device = "/dev/disk/by-id/nvme-WDC_PC_SN720_SDAQNTW-512G-1001_184791804261-part1";
      fsType = "vfat";
    };


  hardware = {
    cpu.intel.updateMicrocode = true;

    bumblebee = {
      enable = true;
      pmMethod = "bbswitch";
    };

    opengl = {
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];
  };

  swapDevices = [ ];
  nix.maxJobs = lib.mkDefault 8;
}
