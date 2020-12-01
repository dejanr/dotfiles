{ boot, lib, pkgs, ... }:
let
  linuxPackages = pkgs.linuxPackages_latest;
  nvidia_x11 = linuxPackages.nvidia_x11;
  nvidia_gl = nvidia_x11.out;
  nvidia_gl_32 = nvidia_x11.lib32;
in
{
  boot = {
    kernelPackages = linuxPackages;
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

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
    };

    kernelParams = [
      "quiet"
      "hugepagesz=1GB"
      "loglevel=3"
      "vga=current" # quiet boot
      "acpi_enforce_resources=lax"
    ];

    blacklistedKernelModules = [
      "fbcon"
      "nouveau"
      "amdgpu"
    ];

    extraModulePackages = [ nvidia_x11 ];
    extraModprobeConfig = ''
      options it87 force_id=0x8628
      options k10temp force=1
    '';

    supportedFilesystems = [ "zfs" ];

    loader = {
      efi.canTouchEfiVariables = true;
      grub.efiSupport = true;
      grub.device = "nodev";
      grub.useOSProber = true;
    };

    cleanTmpDir = true;
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
    { device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_500GB_S4EVNF0M840573B-part1";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_500GB_S4EVNF0M840573B-part2"; }
    ];

  hardware = {
    cpu = {
      amd.updateMicrocode = true;
    };

    nvidia.modesetting.enable = lib.mkForce false;

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = [
        nvidia_gl
        pkgs.vaapiIntel
        pkgs.libvdpau-va-gl
        pkgs.vaapiVdpau
      ];
      extraPackages32 = [ nvidia_gl_32 ];
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
