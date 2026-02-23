{
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  hostName = "framework";
  kernelPackages = pkgs.linuxPackages_6_18;
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    zfs.package = pkgs.zfs_unstable;
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "armv6l-linux"
    ];
    initrd.kernelModules = [
    ];
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "thunderbolt"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];

    kernelModules = [
      "kvm-amd"
      "virtio"
      "v4l2loopback"
      "vfio"
      "vfio_pci"
      "vfio_iommu_type1"
      "virtio"
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
      "amd_iommu=on"
      "iommu=pt"
      "iommu=1"
      "quiet"
      "udev.log_level=3"
      "splash"
      "hugepagesz=1GB"
      "loglevel=3"
      "amd_pstate=active"
    ];

    blacklistedKernelModules = [
      "ath3k"
    ];

    extraModprobeConfig = ''
      options v4l2loopback exclusive_caps=1 video_nr=9 card_label=v4l2
      options kvm-amd nested=1
      options kvm ignore_msrs=1
      options kvm report_ignored_msrs=0
    '';

    supportedFilesystems = [ "zfs" ];

    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 19;
      efi.canTouchEfiVariables = true;
      systemd-boot.memtest86.enable = true;
    };

    tmp.cleanOnBoot = true;
  };

  fileSystems."/" = {
    device = "zpool/root";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/nix" = {
    device = "zpool/nix";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/var" = {
    device = "zpool/var";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/home" = {
    device = "zpool/home";
    fsType = "zfs";
    options = [ "zfsutil" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9A8D-CFC6";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/21ccc592-a18e-4731-9757-38a1216451dd"; }
  ];

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
    cpu = {
      amd.updateMicrocode = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };

    amdgpu.initrd.enable = true;

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
    hardware.bolt.enable = true; # Userspace daemon to enable security levels for Thunderbolt 3 on GNU/Linux.

    udev.extraRules = ''
      # Always authorize thunderbolt connections when they are plugged in.
      ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
    '';

    xserver = {
      videoDrivers = [ "modesetting" ];

      displayManager = {
        xserverArgs = [ "-dpi 92" ];
      };

      screenSection = ''
        Option         "AllowIndirectGLXProtocol" "off"
        Option         "TripleBuffer" "on"
      '';

      # Disable DPMS to prevent display sleep issues with TV
      serverFlagsSection = ''
        Option "BlankTime" "0"
        Option "StandbyTime" "0"
        Option "SuspendTime" "0"
        Option "OffTime" "0"
      '';

      deviceSection = ''
        Option  "DRI" "3"
        Option  "TearFree" "true"
        # Use legacy DPMS instead of modesetting for better TV compatibility
        Option  "HardDPMS" "false"
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
    framework-tool
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  nix.settings.max-jobs = lib.mkDefault 8;
}
