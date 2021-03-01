{ boot, lib, pkgs, ... }:

{
  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

    kernelModules = [
      "kvm-amd"
      "tun"
      "virtio"
      "coretemp"
      "i2c-dev"
      "k10temp"
      "it87"
      "v4l2loopback"
    ];

    kernelPackages = pkgs.linuxPackages_latest;

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
    };

    kernelParams = [
      "quiet"
      "hugepagesz=1GB"
      "loglevel=3"
    ];

    blacklistedKernelModules = [
      "fbcon"
      "nouveau"
    ];

    extraModprobeConfig = ''
      options it87 force_id=0x8628
      options k10temp force=1
    '';


    supportedFilesystems = [ "btrfs" ];

    loader = {
      efi.canTouchEfiVariables = true;
      grub.efiSupport = true;
      grub.device = "nodev";
      grub.useOSProber = true;
      grub.extraEntries = ''
        menuentry "Firmware" {
          fwsetup
        }
        menuentry "Reboot" {
          reboot
        }
        menuentry "Poweroff" {
          halt
        }
      '';
    };

    cleanTmpDir = true;
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/dd307a32-5dd8-40eb-a672-b734aa92f7ff";
      fsType = "btrfs";
      options = [ "subvol=nixos" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/3907-7539";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/49bb4d84-077a-4da7-8e9a-0b33fde0e220"; }
    ];

  hardware = {
    cpu = {
      amd.updateMicrocode = true;
    };

    video.hidpi.enable = lib.mkDefault true;

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = [
        pkgs.rocm-opencl-icd
        pkgs.rocm-opencl-runtime
        pkgs.amdvlk
      ];
      extraPackages32 = [
        pkgs.driversi686Linux.amdvlk
      ];
    };

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];
    enableRedistributableFirmware = true;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  nix.maxJobs = lib.mkDefault 8;
  # High-DPI console
  console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
}
