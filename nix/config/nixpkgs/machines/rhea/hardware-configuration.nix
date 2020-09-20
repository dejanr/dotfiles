{ config, lib, pkgs, ... }:

# ASRock A300
# Ryzen 3400G

{
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

    loader = {
      efi.canTouchEfiVariables = true;
      grub.efiSupport = true;
      grub.device = "nodev";
      grub.useOSProber = true;
    };

    supportedFilesystems = [ "zfs" "exfat" ];
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
      ];
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

  fileSystems."/nix" =
    { device = "zpool/root/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "zpool/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/680F-3735";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/f034af63-e5dd-4308-ae1b-490f46110f9a"; }
    ];

  nix.maxJobs = lib.mkDefault 8;

  # High-DPI console
  console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
}
