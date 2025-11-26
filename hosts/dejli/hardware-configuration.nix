{
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  hostName = "dejli";
  kernelPackages = pkgs.linuxPackages_latest;
in
{
  imports = [ 
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    initrd.kernelModules = [ ];
    initrd.availableKernelModules = [
      "xhci_pci" 
      "virtio_pci"
      "usbhid" 
      "usb_storage"
      "sr_mod" 
    ];

    kernelModules = [
      "v4l2loopback"
      "vfio"
      "vfio_pci"
    ];

    kernelPackages = kernelPackages;

    extraModulePackages = [ kernelPackages.v4l2loopback ];

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
      "vm.max_map_count" = 16777216;
      "fs.file-max" = 524288;
    };

    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "splash"
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
      options v4l2loopback exclusive_caps=1 video_nr=9 card_label=v4l2
      options kvm-amd nested=1
      options kvm ignore_msrs=1
      options kvm report_ignored_msrs=0
      options nvidia_modeset vblank_sem_control=0 nvidia NVreg_PreserveVideoMemoryAllocations=1 NVreg_TemporaryFilePath=/var/tmp
    '';

    initrd.supportedFilesystems = [ ];
    supportedFilesystems = [ ];

    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    tmp.cleanOnBoot = true;
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/4b6c58bf-9a69-403b-beb0-ef9990fc28e0";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/70EE-ABC1";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];

  swapDevices = [
    { device = "/dev/disk/by-label/swap"; }
  ];

  fileSystems."/mnt/shared" = {
    device = "share";
    fsType = "9p";
    options = [
      "trans=virtio"
      "version=9p2000.L"
      "rw"
      "noauto"
      "x-systemd.automount"
    ];
  };

  fileSystems."/mnt/synology/inbox" = {
    device = "100.69.35.105:/volume1/inbox";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "nfsvers=4.1"
    ];
  };

  fileSystems."/mnt/synology/storage" = {
    device = "100.69.35.105:/volume1/storage";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=600"
      "nfsvers=4.1"
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

  hardware = {
    firmware = [ pkgs.linux-firmware ];

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  networking = {
    useDHCP = true;
    dhcpcd.enable = false;
    hostId = "8425e349";
    hostName = "${hostName}";
    useNetworkd = false;
    networkmanager.enable = true;
    networkmanager.plugins = lib.mkForce [ ];
    networkmanager.dns = "systemd-resolved";
    # Use systemd-resolved instead of resolvconf (configured in services.nix)
    # Custom nameservers are set via services.resolved.fallbackDns
    resolvconf.enable = false;
  };

  services = {
    xserver = {
      displayManager = {
        xserverArgs = [ "-dpi 92" ];
      };

      screenSection = ''
      '';

      deviceSection = ''
        Option  "DRI" "3"
        Option  "TearFree" "true"
      '';
    };

    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "ondemand";
        SCHED_POWERSAVE_ON_AC = 0;
        SCHED_POWERSAVE_ON_BAT = 1;
        ENERGY_PERF_POLICY_ON_AC = "performance";
        ENERGY_PERF_POLICY_ON_BAT = "powersave";
        PCIE_ASPM_ON_AC = "performance";
        PCIE_ASPM_ON_BAT = "powersave";
        WIFI_PWR_ON_AC = 1;
        WIFI_PWR_ON_BAT = 5;
        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";
        USB_BLACKLIST_WWAN = 1;
        SOUND_POWER_SAVE_ON_BAT = 0;
        USB_AUTOSUSPEND = 0;
        CONTROL_USB_AUTOSUSPEND = "off";
        DEVICES_TO_DISABLE_ON_STARTUP = "";
      };
    };
  };

  environment = {
    etc."X11/Xresources".text = ''
      Xft.dpi: 92
    '';
  };

  environment.systemPackages = with pkgs; [
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    libglvnd
  ];

  nix.settings.max-jobs = lib.mkDefault 8;
};
}
