{ config, lib, pkgs, ... }:

# Asus Z97-C
# Intel i7 4970K

let
  nvidia_x11 = pkgs.linuxPackages.nvidia_x11;
  nvidia_gl = nvidia_x11.out;
  nvidia_gl_32 = nvidia_x11.lib32;
in
{
  imports = [
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

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

    zfs.enableUnstable = true;

    loader = {
      efi.canTouchEfiVariables = true;
      grub.efiSupport = true;
      grub.device = "nodev";
      grub.useOSProber = true;
    };

    cleanTmpDir = true;
  };

  fileSystems."/" =
    { device = "rpool/root/nixos";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "rpool/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/4830-6CE0";
      fsType = "vfat";
    };

  swapDevices = [];

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

  ## CPU
  nix.maxJobs = lib.mkDefault 8;

  services = {
    ## SSDs
    services.fstrim.enable = true;
    # unifi
    unifi.enable = true;
    unifi.openPorts = true;

    xserver = {
      enable = true;
      xkbOptions = "compose:ralt";
      videoDrivers = [ "nvidia" ];
      displayManager = {
        xserverArgs = [ "-dpi 109" ];
      };

      deviceSection = ''
        Driver "nvidia"
        VendorName "NVIDIA Corporation"
        BusID "PCI:1:0:0"
      '';

      screenSection = ''
        Option         "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
        Option         "AllowIndirectGLXProtocol" "off"
        Option         "TripleBuffer" "on"
      '';
    };

    tlp = {
      enable = true;
      extraConfig = ''
        CPU_SCALING_GOVERNOR_ON_AC=performance
        CPU_SCALING_GOVERNOR_ON_BAT=ondemand
        SCHED_POWERSAVE_ON_AC=0
        SCHED_POWERSAVE_ON_BAT=1
        ENERGY_PERF_POLICY_ON_AC=performance
        ENERGY_PERF_POLICY_ON_BAT=powersave
        PCIE_ASPM_ON_AC=performance
        PCIE_ASPM_ON_BAT=powersave
        WIFI_PWR_ON_AC=1
        WIFI_PWR_ON_BAT=5
        RUNTIME_PM_ON_AC=on
        RUNTIME_PM_ON_BAT=auto
        USB_BLACKLIST_WWAN=1
        SOUND_POWER_SAVE_ON_BAT=0
        USB_AUTOSUSPEND=0
        CONTROL_USB_AUTOSUSPEND="off"
        DEVICES_TO_DISABLE_ON_STARTUP=""
      '';
    };
  };

  environment = {
    etc."X11/Xresources".text = ''
      Xft.dpi: 109
    '';
    systemPackages = [ nvidia_x11 ];
  };

  systemd.services.nvidia-control-devices = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = "${nvidia_x11.bin}/bin/nvidia-smi";
  };

  virtualisation.docker.enableNvidia = true;
}
