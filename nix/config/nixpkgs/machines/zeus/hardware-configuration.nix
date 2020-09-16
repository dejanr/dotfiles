{ boot, lib, pkgs, ... }:
let
  nvidia_x11 = pkgs.linuxPackages.nvidia_x11;
  nvidia_gl = nvidia_x11.out;
  nvidia_gl_32 = nvidia_x11.lib32;
in
{
  boot = {
    kernelPackages = pkgs.linuxPackages;
    initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" ];
    initrd.kernelModules = [ "vfio_pci" "fbcon" ];
    kernelModules = [
      "kvm"
      "kvm-intel"
      "vfio"
      "vfio_pci"
      "vfio_iommu_type1"
      "vfio_virqfd"
      "tun"
      "virtio"
      "coretemp"
      "nct6775"
    ];
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
    };
    kernelParams = [
      #"vfio-pci.ids=10de:1c03,10de:10f1"

      # Use IOMMU
      #"intel_iommu=on"
      #"intel_iommu=igfx_off"
      #"i915.preliminary_hw_support=1"
      #"i915.enable_hd_vgaarb=1"
      #"vfio_iommu_type1.allow_unsafe_interrupts=1"

      #"kvm.allow_unsafe_assigned_interrupts=1"

      # Needed by OS X
      #"kvm.ignore_msrs=1"
      #"kvm_intel.nested=1"
      #"kvm_intel.emulate_invalid_guest_state=0"

      # Only schedule cpus 0,1
      # "isolcpus=1-3,5-7"

      "hugepagesz=1GB"
    ];
    blacklistedKernelModules = [
      "fbcon"
      "nouveau"
    ];
    extraModulePackages = [ nvidia_x11 ];
    extraModprobeConfig = ''
      # 41:00.0 VGA compatible controller: NVIDIA Corporation GP106 [GeForce GTX 1060 6GB] (rev a1)
      # 41:00.1 Audio device: NVIDIA Corporation GP106 High Definition Audio Controller (rev a1)

      # Assign devices to vfio
      #options vfio-pci ids=10de:1c03,10de:10f1
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
