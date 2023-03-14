{ boot, lib, pkgs, modulesPath, ... }:

let
  hostName = "omega";
  kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
in {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    initrd.preDeviceCommands = ''
      # 0000:04:00.0 nvidia
      # 0000:04:00.1 nvidia audio
      #DEVS="0000:04:00.0 0000:04:00.1"
      #for DEV in $DEVS; do
      #  echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
      #done
      #modprobe -i vfio-pci
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
      options kvm-amd nested=1
      options kvm xignore_msrs=1
    '';

    initrd.supportedFilesystems = [ ];
    supportedFilesystems = [ ];

    loader = {
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
      grub.enable = true;
      grub.efiSupport = true;
      grub.version = 2;
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

  time.hardwareClockInLocalTime = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/90d2b118-6b83-4897-9149-39dc7d4f0487";
      fsType = "ext4";
    };

  fileSystems."/boot/efi" =
    { device = "/dev/disk/by-uuid/B53C-141D";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/194d14a0-0daa-491c-b247-1555e7154f75"; }
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
      videoDrivers = [ "nvidia" ];

      displayManager = {
        xserverArgs = [ "-dpi 109" ];
      };

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

    systemPackages = with pkgs; [
      (pkgs.python310.withPackages (ps: with ps;
        let
          mypytorch = pytorch.override {
            cudaSupport = true;
            MPISupport = true;
          };
        in [ mypytorch ]))
    ];
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  nix.settings.max-jobs = lib.mkDefault 8;
}
