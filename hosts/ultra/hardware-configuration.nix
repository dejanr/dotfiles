{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  hostName = "ultra";
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/46f7a6c6-7241-475d-b2b8-5ddd28807843";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/40DC-1417";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  fileSystems."/home/dejanr/.cache/qutebrowser" = {
    device = "tmpfs";
    fsType = "tmpfs";
    options = [
      "rw"
      "nosuid"
      "nodev"
      "size=512M"
      "mode=0700"
      "uid=1000"
      "gid=100"
    ];
  };

  swapDevices = [ ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  networking = {
    useDHCP = true;
    dhcpcd.enable = false;
    hostId = "8425e349";
    hostName = "${hostName}";
    useNetworkd = false;
    networkmanager.enable = true;
  };

  hardware = {
    asahi.peripheralFirmwareDirectory = ./firmware;

    # Enable Vulkan and OpenGL
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vulkan-loader
        vulkan-validation-layers
        libglvnd
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools # vulkaninfo, vkcube
    mesa-demos # glxgears etc
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
