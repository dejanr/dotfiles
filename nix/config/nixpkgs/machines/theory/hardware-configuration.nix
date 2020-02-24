{ config, lib, pkgs, ... }:

{
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

    zfs.enableUnstable = true;

    initrd = {
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" ];
      luks.devices.decrypted-hdd = {
        device = "/dev/disk/by-id/nvme-WDC_PC_SN720_SDAQNTW-512G-1001_184791804261-part2";
        keyFile = "/keyfile.bin";
      };
    };

    kernelModules = [
      "acpi_call"
      "kvm-intel"
      "i915"
      "modesetting"
      "thinkpad_acpi"
    ];

    blacklistedKernelModules = [
      "fbcon"
      "nouveau"
    ];

    kernelParams = [
      "i915.enable_fbc=1"
      "i915.enable_psr=0"
      "snd_hda_intel.power_save=1"
      "bbswitch.load_state=0"
      "bbswitch.unload_state=1"
    ];

    extraModprobeConfig = ''
      options thinkpad_acpi experimental=1 fan_control=1
    '';

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
      "kernel.nmi_watchdog" = 0;
      "vm.dirty_writeback_centisecs" = 1500;
      "vm.laptop_mode" = 5;
    };

    supportedFilesystems = [ "zfs" ];
    cleanTmpDir = true;

    loader = {
      efi.efiSysMountPoint = "/efi";

      grub = {
      device = "nodev";
      efiSupport = true;
      extraInitrd = "/boot/initrd.keys.gz";
      enableCryptodisk = true;
      copyKernels = true;
      zfsSupport = true;
        efiInstallAsRemovable = true;
      };
    };
  };

  fileSystems."/" =
    { device = "zroot/root";
      fsType = "zfs";
    };

  fileSystems."/efi" =
    { device = "/dev/disk/by-id/nvme-WDC_PC_SN720_SDAQNTW-512G-1001_184791804261-part1";
      fsType = "vfat";
    };


  hardware = {
    cpu.intel.updateMicrocode = true;

    bumblebee = {
      enable = true;
      pmMethod = "bbswitch";
    };

    nvidiaOptimus.disable = true;


    opengl = {
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
        linuxPackages.nvidia_x11.out
      ];
      extraPackages32 = with pkgs; [
        linuxPackages.nvidia_x11.lib32
      ];
    };

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];
  };

  services.xserver = {
    screenSection = ''
      Option         "metamodes" "nvidia-auto-select +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
      Option         "AllowIndirectGLXProtocol" "off"
      Option         "TripleBuffer" "on"
    '';

  };

  services.thinkfan = {
    enable = true;
  };

  services.undervolt = {
    enable = true;
    tempAc = "80";
    tempBat = "70";
  };

  swapDevices = [ ];
  nix.maxJobs = lib.mkDefault 8;
}
