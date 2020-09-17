{ boot, lib, pkgs, ... }:
let
  nvidia_x11 = pkgs.linuxPackages_latest.nvidia_x11;
  nvidia_gl = nvidia_x11.out;
  nvidia_gl_32 = nvidia_x11.lib32;
in
{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "vfio_pci" "fbcon" ];
    initrd.kernelModules = [ ];
    initrd.preDeviceCommands = ''
      # 0000:01:00.0 nvidia
      # 0000:01:00.1 nvidia
      # 0000:05:00.0 Ethernet
      # 0000:05:00.1 Ethernet
      DEVS="0000:01:00.0 0000:01:00.1 0000:05:00.0 0000:05:00.1"
      for DEV in $DEVS; do
        echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
      done
      modprobe -i vfio-pci
    '';
    kernelModules = [
      "kvm-intel"
      #"vfio"
      #"vfio_pci"
      #"vfio_iommu_type1"
      #"vfio_virqfd"
      "tun"
      "virtio"
      "coretemp"
      "nct6775"
    ];
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
    };
    kernelParams = [
      "intel_iommu=on"
      "hugepagesz=1GB"
    ];
    blacklistedKernelModules = [
      "fbcon"
      "nouveau"
    ];
    extraModulePackages = [ nvidia_x11 ];
    extraModprobeConfig = ''
      options snd-hda-intel vid=8086 pid=8ca0 snoop=0
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

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/6D9B-B398";
      fsType = "vfat";
    };

  fileSystems."/nix" =
    { device = "zpool/root/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "zpool/home";
      fsType = "zfs";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/b477f8bc-6496-4ae4-8366-8d3ed518bc3d"; }
      { device = "/dev/disk/by-uuid/f8eb046e-cd09-4ce7-aa1c-3c00980aa6bb"; }
    ];

  hardware = {
    cpu.intel.updateMicrocode = true;
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
  };

  nix.maxJobs = lib.mkDefault 8;
}
