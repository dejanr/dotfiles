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
      linuxPackages_latest.v4l2loopback
    ];

    kernelPackages = pkgs.linuxPackages_latest;

    kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
      "vm.swappiness" = 10;
    };

    kernelParams = [
      "quiet"
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
