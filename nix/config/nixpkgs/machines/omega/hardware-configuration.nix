{ boot, lib, pkgs, ... }:

{
  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    initrd.preDeviceCommands = ''
      # 0000:0d:00.0 6800xt
      # 0000:0d:00.1 6800xt audio
      DEVS=""
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
      "it87"
      "v4l2loopback"
      "vfio"
      "vfio_pci"
      "vfio_iommu_type1"
      "vfio_virqfd"
      "virtio" # paravirtual 3D graphics driver based on virgl
    ];

    extraModulePackages = with pkgs; [
      linuxPackages_5_12.v4l2loopback
    ];

    kernelPackages = pkgs.linuxPackages_5_12;

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
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

    kernelPatches = let
      fsync = rec {
        name = "v5.12-fsync";
        patch = pkgs.fetchpatch {
          name = name + ".patch";
          url = "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/linux-tkg-patches/5.12/0007-v5.12-fsync.patch";
          sha256 = "2hHSMHtr4B0bZ1zehOJL1NMgVFgOT+gS+TDb3IgS3x4=";
        };
      };

      futex2 = rec {
        name = "v5.12-futex2";
        patch = pkgs.fetchpatch {
          name = name + ".patch";
          url = "https://raw.githubusercontent.com/sirlucjan/kernel-patches/master/5.12/futex2-stable-patches/0001-futex2-resync-from-gitlab.collabora.com.patch";
          sha256 = "lcNTIQ9Xr2xKTePrdo8JVivOMgTIMUBJa/LUUiEjGd8=";
        };
      };

      enableFutex2 = {
        name = "futex2-config";
        patch = null;
        extraConfig = ''
          FUTEX2 y
        '';
      };
    in [ fsync futex2 enableFutex2 ];

    blacklistedKernelModules = [
      "fbcon"
      "nouveau"
    ];

    extraModprobeConfig = ''
      options it87 force_id=0x8628
      options k10temp force=1
      options v4l2loopback exclusive_caps=1 video_nr=9 card_label=v4l2
    '';

    initrd.supportedFilesystems = [ "zfs" ];
    supportedFilesystems = [ "zfs" ];

    zfs.enableUnstable = true;

    loader = {
      efi.canTouchEfiVariables = true;
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

    cleanTmpDir = true;
  };

  fileSystems."/" =
    { device = "zpool/root/nixos";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/F25D-8EAF";
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
    [ { device = "/dev/disk/by-uuid/2b15d6da-dad7-4e46-b657-491bb57fc93c"; }
    ];

  hardware = {
    cpu = {
      amd.updateMicrocode = true;
    };

    video.hidpi.enable = lib.mkDefault true;

    opengl = let
      mesaDrivers = pkgs: ((pkgs.mesa.override {
        stdenv = pkgs.impureUseNativeOptimizations (if !pkgs.stdenv.is32bit then
        pkgs.llvmPackages_latest.stdenv
        else
        pkgs.stdenv);

        galliumDrivers = [ "radeonsi" "virgl" "svga" "swrast" "zink" ];
      }).overrideAttrs (oldAttrs: rec {
        version = "21.0.0";

        src = pkgs.fetchgit {
          url = "https://gitlab.freedesktop.org/mesa/mesa.git";
          # 01-30-21
          rev = "205e737f51baf2958c047ae6ce3af66bffb52b37";
          sha256 = "WkGiW06wEnDHTr2dIVHAcZlWLMvacHh/m4P+eVD4huI=";
        };

        mesonFlags = oldAttrs.mesonFlags ++ [
          "-Dmicrosoft-clc=disabled"
          "-Dosmesa=true"
        ];

        # For zink driver
        buildInputs = oldAttrs.buildInputs ++ [
          pkgs.vulkan-loader
        ];

        patches = [
          ./patches/disk_cache-include-dri-driver-path-in-cache-key.patch
        ];
      })).drivers;
    in {
      driSupport = true;
      driSupport32Bit = true;

      package = mesaDrivers pkgs;
      package32 = mesaDrivers pkgs.pkgsi686Linux;

      extraPackages = with pkgs; [
        amdvlk
        rocm-opencl-icd
        rocm-opencl-runtime
      ];

      extraPackages32 = with pkgs; [
        driversi686Linux.amdvlk
      ];
    };

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];

    enableRedistributableFirmware = true;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  nix.maxJobs = lib.mkDefault 8;

  # High-DPI console
  console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
}
