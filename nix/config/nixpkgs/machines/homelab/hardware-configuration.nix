{ config, lib, pkgs, ... }:

{
  boot = {
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
      "quiet nomodeset"

      #"vfio-pci.ids=10de:1c03,10de:10f1"

      # Use IOMMU
      "intel_iommu=on"
      "intel_iommu=igfx_off"
      "i915.preliminary_hw_support=1"
      "i915.enable_hd_vgaarb=1"
      "vfio_iommu_type1.allow_unsafe_interrupts=1"

      "kvm.allow_unsafe_assigned_interrupts=1"

      # Needed by OS X
      "kvm.ignore_msrs=1"
      "kvm_intel.nested=1"
      "kvm_intel.emulate_invalid_guest_state=0"

      # Only schedule cpus 0,1
      # "isolcpus=1-3,5-7"

      "hugepagesz=1GB"
    ];
    blacklistedKernelModules = [
      "nouveau" "nvidia"
    ];
    extraModulePackages = [];
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
      efi.efiSysMountPoint = "/boot";

      grub.enable = true;
      grub.version = 2;
      grub.devices = ["nodev"];
      grub.efiSupport = true;
      grub.useOSProber = true;
    };

    cleanTmpDir = true;
  };

  fileSystems."/" = {
    device = "rpool/root/nixos";
    fsType = "zfs";
  };

  fileSystems."/home" = {
    device = "rpool/home";
    fsType = "zfs";
  };

  fileSystems."/boot" = {
    device = "/dev/sdb1";
    fsType = "vfat";
  };

  swapDevices = [ ];

  hardware = {
    cpu.intel.updateMicrocode = true;

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vaapiIntel
        libvdpau-va-gl
        vaapiVdpau
      ];
    };
  };

  nix.maxJobs = lib.mkDefault 8;
}
