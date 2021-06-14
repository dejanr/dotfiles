{ boot, lib, pkgs, ... }:

{
  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

    kernelModules = [
      "kvm-amd"
      "tun"
      "virtio"
      "coretemp"
      "i2c-dev"
      "k10temp"
      "it87"
      "v4l2loopback"
    ];

    extraModulePackages = with pkgs; [
      linuxPackages_5_11.v4l2loopback
    ];

    kernelPackages = pkgs.linuxPackages_5_11;

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
    };

    kernelParams = [
      "quiet"
      "hugepagesz=1GB"
      "loglevel=3"
    ];

    kernelPatches = let
      # For Wine
      fsync = rec {
        name = "v5.11-fsync";
        patch = pkgs.fetchpatch {
          name = name + ".patch";
          url = "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/linux-tkg-patches/5.11/0007-v5.11-fsync.patch";
          sha256 = "2hHSMHtr4B0bZ1zehOJL1NMgVFgOT+gS+TDb3IgS3x4=";
        };
      };

      futex2 = rec {
        name = "v5.11-futex2";
        patch = pkgs.fetchpatch {
          name = name + ".patch";
          url = "https://raw.githubusercontent.com/sirlucjan/kernel-patches/master/5.11/futex2-dev-trunk-patches-v4/0001-futex2-resync-from-gitlab.collabora.com.patch";
          sha256 = "a/5TL1OLTC7WILIKA1Vprwdgp2mo7tf3VCukyACdvcI=";
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

    supportedFilesystems = [ "btrfs" ];

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
    { device = "/dev/nvme0n1p3";
    fsType = "btrfs";
    options = [ "subvol=nixos" ];
  };

  fileSystems."/boot" =
    { device = "/dev/nvme0n1p1";
    fsType = "vfat";
  };

  swapDevices =
    [ { device = "/dev/nvme0n1p2"; }
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
        version = "21.2.0";

        src = pkgs.fetchgit {
          url = "https://gitlab.freedesktop.org/mesa/mesa.git";
          # 14-07-21
          rev = "d41faa69ca4e05c0099ffce35824e2abd3782981";
          sha256 = "Lf9tFXMIhR+9nIPun+2tch8BusGEB6PscatDwKBmjSQ=";
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
