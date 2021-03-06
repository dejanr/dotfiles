{ config, lib, pkgs, ... }:

# ASRock A300
# Ryzen 2400G

{
  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" "lm92" ];
    initrd.supportedFilesystems = [ "zfs" ];
    kernelModules = [ "kvm-amd" "nct6775" "k10temp" "coretemp" ];
    kernelPackages = pkgs.linuxPackages_5_4;
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
    '';

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
      "kernel.nmi_watchdog" = 0;
    };

    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    supportedFilesystems = [ "zfs" "exfat" ];
    zfs.enableUnstable = true;
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
        intel-media-driver # only available starting nixos-19.03 or the current nixos-unstable
      ];
    };

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];

    enableRedistributableFirmware = true;
  };

  fileSystems."/" =
    {
      device = "zpool/root/nixos";
      fsType = "zfs";
    };

  fileSystems."/home" =
    {
      device = "zpool/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/4182-AF1E";
      fsType = "vfat";
    };

  swapDevices = [];

  nix.maxJobs = lib.mkDefault 8;
}
