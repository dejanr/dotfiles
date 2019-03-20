{ config, lib, pkgs, ... }:

let
  username = "dejanr";
  hostName = "theory";
in {
  imports =
    [
      ../../roles/common.nix
      ../../roles/desktop.nix
      ../../roles/i3.nix
      ../../roles/autolock.nix
      ../../roles/multimedia.nix
      ../../roles/development.nix
      ../../roles/services.nix
      ../../roles/fonts.nix
   ];

  nix.useSandbox = false;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;

  nix.nixPath = [
    "nixpkgs=channel:nixpkgs-unstable"
    "nixos-config=/home/${username}/.config/nixpkgs/machines/${hostName}/configuration.nix"
    "nixpkgs-overlays=/home/${username}/.config/nixpkgs/overlays"
  ];

  nixpkgs.overlays =
    let
      paths = [
        ../../overlays
      ];
    in with builtins;
      concatMap (path:
        (map (n: import (path + ("/" + n)))
          (filter (n: match ".*\\.nix" n != null ||
                    pathExists (path + ("/" + n + "/default.nix")))
                    (attrNames (readDir path))))) paths;

  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];

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
    ];

    blacklistedKernelModules = [
      "fbcon"
      "bbswitch"
      "nvidia"
      "nvidia-drm"
      "nvidia-uvm"
      "nvidia-modesetting"
      "nouveau"
    ];

    kernelParams = [
      "i915.enable_fbc=1"
      "i915.enable_psr=2"
    ];

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
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

  swapDevices = [ ];

  networking = {
    hostName = "theory";
    hostId = "7392bf5d";
  };

  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  hardware.opengl.extraPackages = with pkgs; [
    vaapiIntel
    vaapiVdpau
    libvdpau-va-gl
  ];

  hardware.bumblebee = {
    enable = true;
    pmMethod = "bbswitch";
  };

  services = {
    xserver = {
      enable = true;
      modules = [ pkgs.xf86_input_mtrack ];
      videoDrivers = [ "intel" ];

      synaptics.enable = false;

      libinput = {
        enable = true;
        disableWhileTyping = true;
        scrollMethod = "twofinger";
        tapping = true;
      };

      extraConfig = ''
        Section "InputClass"
        Identifier     "Enable libinput for TrackPoint"
        MatchIsPointer "on"
        Driver         "libinput"
        EndSection
      '';

      deviceSection = ''
        Driver "intel"
        Option "TearFree" "true"
        Option "DRI" "3"
        Option "Backlight" "intel_backlight"
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
        USB_AUTOSUSPEND=0
        USB_BLACKLIST_WWAN=1
        DEVICES_TO_DISABLE_ON_STARTUP="bluetooth"
        SOUND_POWER_SAVE_ON_BAT=0
      '';
    };
  };

  environment = {
    etc."X11/Xresources".text = ''
      Xft.dpi: 144
    '';
    variables.QT_AUTO_SCREEN_SCALE_FACTOR = "1";
    variables.GDK_SCALE = "2";
    variables.GDK_DPI_SCALE = "0.5";
  };

  programs.light.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";

  nix.maxJobs = lib.mkDefault 8;

  system.stateVersion = "18.09";
}

