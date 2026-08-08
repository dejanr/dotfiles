{
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  hostName = "omega";
  kernelPackages = pkgs.linuxPackages_6_18;
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    zfs.package = pkgs.zfs_unstable;
    zfs.forceImportRoot = false;
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "armv6l-linux"
    ];
    initrd.kernelModules = [ ];
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    kernelModules = [
      "kvm-amd"
      "tun"
      "virtio"
      "coretemp"
      "i2c-dev"
      "k10temp"
      "v4l2loopback"
      "vfio"
      "vfio_pci"
      "vfio_iommu_type1"
      "virtio" # paravirtual 3D graphics driver based on virgl
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
    ];

    blacklistedKernelModules = [ "fbcon" ];

    extraModprobeConfig = ''
      options it87 force_id=0x8628
      options k10temp force=1
      options v4l2loopback exclusive_caps=1 video_nr=9 card_label=v4l2
      options kvm-amd nested=1
      options kvm ignore_msrs=1
      options kvm report_ignored_msrs=0
    '';

    initrd.supportedFilesystems = [ ];
    supportedFilesystems = [ ];

    loader = {
      grub.configurationLimit = 19;
      systemd-boot.configurationLimit = 19;
      efi.canTouchEfiVariables = true;
      grub.enable = true;
      grub.efiSupport = true;
      grub.device = "nodev";
      grub.useOSProber = false;
      systemd-boot.memtest86.enable = true;
      grub.memtest86.enable = true;
      grub.extraEntries = ''
        menuentry "Windows Boot Manager" {
          search --fs-uuid --no-floppy --set=root 377B-0904
          chainloader /EFI/Microsoft/Boot/bootmgfw.efi
        }
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

    tmp.cleanOnBoot = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/90ce2d6c-b484-4be2-b5af-cca923deb919";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7136-45B9";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/00ec3f8f-c119-4ec3-9d3b-6a477af0d807"; }
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

    amdgpu = {
      initrd.enable = true;
      opencl.enable = true;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
    };

    firmware = [ pkgs.linux-firmware ];

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

  networking = {
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
      videoDrivers = [ "amdgpu" ];

      displayManager = {
        xserverArgs = [ "-dpi 92" ];
      };

      screenSection = ''
        Option         "AllowIndirectGLXProtocol" "off"
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
}
