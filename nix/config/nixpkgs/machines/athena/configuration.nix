{ config, lib, pkgs, ... }:
let
  hostName = "athena";
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../roles/common.nix
      ../../roles/shells/bash
      ../../roles/fonts.nix
      ../../roles/multimedia.nix
      ../../roles/desktop.nix
      ../../roles/i3.nix
      ../../roles/development.nix
      ../../roles/services.nix
      ../../roles/games.nix
    ];

  nix.useSandbox = true;

  networking = {
    hostName = hostName;
    hostId = "8425e349";
  };

  services = {
    xserver = {
      enable = true;
      useGlamor = true;
      videoDrivers = [ "amdgpu" ];

      deviceSection = ''
        Option "TearFree" "true"
        Option "DRI" "3"
      '';

      displayManager = {
        xserverArgs = [ "-dpi 109" ];
      };
    };

    tlp = {
      enable = true;
    };
  };

  environment = {
    etc."X11/Xresources".text = ''
      Xft.dpi: 109
    '';

    systemPackages = with pkgs; [
      libgphoto2 # A library for accessing digital cameras
      gphoto2 # A ready to use set of digital camera software applications
      gphoto2fs # mount camera as fs
    ];
  };

  fonts.fontconfig.dpi = 109;

  programs.light.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";

  system.stateVersion = "19.09";
}
