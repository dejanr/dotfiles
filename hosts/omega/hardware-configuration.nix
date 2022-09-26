{ boot, lib, pkgs, modulesPath, ... }:

let
  hostName = "omega";
  kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    initrd.preDeviceCommands = ''
      # 0000:04:00.0 nvidia
      # 0000:04:00.1 nvidia audio
      DEVS="0000:04:00.0 0000:04:00.1"
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

    extraModulePackages = with kernelPackages; [
      v4l2loopback
    ];

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
      "vm.max_map_count" = 16777216;
    };

    kernelParams = [
      "amd_iommu=on"
      "iommu=pt"
      "iommu=1"
      "video=efifb:off"
      "quiet"
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
    '';

    initrd.supportedFilesystems = [ ];
    supportedFilesystems = [ ];

    loader = {
      grub.enable = true;
      efi.canTouchEfiVariables = true;
      grub.device = "/dev/nvme0n1";
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
    { device = "/dev/disk/by-uuid/0a75cccd-258e-4fbb-a4f0-fb37d259bea5";
      fsType = "ext4";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/a4c9c619-2088-46dd-ab1b-c22aba495cdc"; }
    ];

  hardware = {
    cpu = {
      amd.updateMicrocode = true;
    };

    video.hidpi.enable = lib.mkDefault true;

    opengl = {
      driSupport = lib.mkDefault true;
      driSupport32Bit = lib.mkDefault true;
      extraPackages = with pkgs; [
        rocm-opencl-icd
        rocm-opencl-runtime
        amdvlk
      ];
    };

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
  };

  networking = {
    useDHCP = lib.mkDefault true;
    hostId = "8425e349";
    hostName = "${hostName}";
  };

  services = {
    xserver = {
      enable = true;
      videoDrivers = [ "amdgpu" ];

      displayManager = {
        xserverArgs = [ "-dpi 109" ];
      };

      deviceSection = ''
          Option "AccelMethod" "glamor"
          Option "DRI" "3"
          Option "TearFree" "on"
          Option "ColorTiling" "on"
          Option "ColorTiling2D" "on"
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
    systemPackages = [ ];
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  nix.settings.max-jobs = lib.mkDefault 8;
}
