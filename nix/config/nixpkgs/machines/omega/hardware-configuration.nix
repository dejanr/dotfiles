{ boot, lib, pkgs, ... }:

let
  kernelPackages = pkgs.linuxPackages_latest;
in {
  boot = {
    initrd.kernelModules = [ "amdgpu" ];
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];
    initrd.preDeviceCommands = ''
      # 0000:04:00.0 nvidia
      # 0000:04:00.1 nvidia audio
      DEVS="0000:04:00.0 0000:04:00.1"
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

    kernelPackages = kernelPackages;

    extraModulePackages = with kernelPackages; [
      v4l2loopback
    ];

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
      futex2 = rec {
        name = "v5.14-futex2";
        patch = pkgs.fetchpatch {
          name = name + ".patch";
          url = "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/linux-tkg-patches/5.14/0007-v5.14-futex2_interface.patch";
          sha256 = "EUS6XJwcGqcQLLxhPgdYdG3oB3qxsJueGXn7tLaEorc=";
        };
      };

      winesync = rec {
        name = "v5.14-winesync";
        patch = pkgs.fetchpatch {
          name = name + ".patch";
          url = "https://raw.githubusercontent.com/Frogging-Family/linux-tkg/master/linux-tkg-patches/5.14/0007-v5.14-winesync.patch";
          sha256 = "MHNc4K3wmBP4EHcx48pcu7fI7WXjfcqIhW1+Zt8zpng=";
        };
      };

      enableFutex2 = {
        name = "futex2-config";
        patch = null;
        extraConfig = ''
          FUTEX2 y
        '';
      };
    in #[ futex2 winesync enableFutex2 ]; # TODO: fix futex2 patch
    [ winesync ];

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

  fileSystems."/nix" =
    { device = "zpool/root/nix";
      fsType = "zfs";
    };

  fileSystems."/home" =
    { device = "zpool/home";
      fsType = "zfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/2DA1-8C8C";
      fsType = "vfat";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/6dd43542-2512-436f-b572-ce2a787aadc1"; }
    ];

  hardware = {
    cpu = {
      amd.updateMicrocode = true;
    };

    video.hidpi.enable = lib.mkDefault true;

    opengl = let
      # mesa with zink driver
      # TODO: enable building with b_lto
      mesaDrivers = pkgs: ((pkgs.mesa.override {
        stdenv = pkgs.impureUseNativeOptimizations (if !pkgs.stdenv.is32bit then
          pkgs.llvmPackages_latest.stdenv
        else
          # Using LLVM for 32-bit builds requires us to build GCC and LLVM, which isn't very nice
          pkgs.stdenv);

        galliumDrivers = [ "radeonsi" "virgl" "svga" "swrast" "zink" ];
      }).overrideAttrs (oldAttrs: rec {
        # For zink driver
        buildInputs = oldAttrs.buildInputs ++ [
          pkgs.vulkan-loader
        ];

      })).drivers;
    in {
      driSupport = true;
      driSupport32Bit = true;

      package = mesaDrivers pkgs;
      package32 = mesaDrivers pkgs.pkgsi686Linux;

      extraPackages = with pkgs; [
      ];

      extraPackages32 = with pkgs; [
      ];
    };

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];

    enableRedistributableFirmware = true;
    enableAllFirmware = true;
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  nix.maxJobs = lib.mkDefault 8;

  # High-DPI console
  console.font = lib.mkDefault "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
}
