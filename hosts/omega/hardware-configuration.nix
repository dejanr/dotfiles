{ config, boot, lib, pkgs, modulesPath, ... }:

# IOMMU Group 42:
# 	35:00.0 VGA compatible controller [0300]: NVIDIA Corporation GP106 [GeForce GTX 1060 6GB] [10de:1c03] (rev a1)
# 	35:00.1 Audio device [0403]: NVIDIA Corporation GP106 High Definition Audio Controller [10de:10f1] (rev a1)

let
  hostName = "omega";
  kernelPackages = pkgs.linuxPackages_zen;
  deviceIDs = [ "0000:34:00.0" "0000:34:00.1" ];
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.kernelModules = [ "nvidia" ];
    initrd.availableKernelModules =
      [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    initrd.preDeviceCommands = ''
      DEVS="0000:34:00.0 0000:34:00.1"
      for DEV in $DEVS; do
        echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
      done
      modprobe -i vfio-pci
    '';

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
      "vfio_virqfd"
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
      ("vfio-pci.ids=" + lib.concatStringsSep "," deviceIDs)
    ];

    blacklistedKernelModules = [ "fbcon" "nouveau" ];

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

    tmp.cleanOnBoot = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/90d2b118-6b83-4897-9149-39dc7d4f0487";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/0CC7-A2E4";
    fsType = "vfat";
  };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/194d14a0-0daa-491c-b247-1555e7154f75"; }];

  fileSystems."/mnt/synology/inbox" = {
    device = "100.69.35.105:/volume1/inbox";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" "nfsvers=4.1" ];
  };

  fileSystems."/mnt/synology/storage" = {
    device = "100.69.35.105:/volume1/storage";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=600" "nfsvers=4.1" ];
  };

  hardware = {
    cpu = { amd.updateMicrocode = true; };

    graphics = {
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        vaapiVdpau
        libvdpau-va-gl
      ];
    };

    firmware = [ pkgs.firmwareLinuxNonfree ];

    enableRedistributableFirmware = true;
    enableAllFirmware = true;

    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = kernelPackages.nvidiaPackages.beta;
    };
  };

  networking = {
    useDHCP = lib.mkDefault true;
    hostId = "8425e349";
    hostName = "${hostName}";
  };

  services = {
    hardware.bolt.enable =
      true; # Userspace daemon to enable security levels for Thunderbolt 3 on GNU/Linux.

    udev.extraRules = ''
      # Always authorize thunderbolt connections when they are plugged in.
      ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{authorized}=="0", ATTR{authorized}="1"
    '';

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];

      displayManager = { xserverArgs = [ "-dpi 109" ]; };

      screenSection = ''
        Option         "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
        Option         "AllowIndirectGLXProtocol" "off"
        Option         "TripleBuffer" "on"
      '';

      deviceSection = ''
        Option "ForceCompositionPipeline" "On"
        Option "ForceFullCompositionPipeline" "On"
        Option "AllowGSYNCCompatible" "On"
        Option "AllowIndirectGLXProtocol" "off"
        Option "TripleBuffer" "on"
        Option  "Stereo" "0"
        Option  "nvidiaXineramaInfoOrder" "DFP-1"
        Option  "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On, AllowGSYNCCompatible=On}"
        Option  "SLI" "Off"
        Option  "MultiGPU" "Off"
        Option  "BaseMosaic" "off"
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
      Xft.dpi: 109
    '';
  };

  environment.systemPackages = with pkgs; [
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    libglvnd
  ];

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  nix.settings.max-jobs = lib.mkDefault 8;
}
