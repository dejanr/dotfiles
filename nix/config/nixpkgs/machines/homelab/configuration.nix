{ config, lib, pkgs, ... }:

with lib;

let
  username = "dejanr";
  hostName = "homelab";
in {
  imports = [
    ./hardware-configuration.nix
    ../../roles/common.nix
    ../../roles/fonts.nix
    ../../roles/multimedia.nix
    ../../roles/desktop.nix
    ../../roles/i3.nix
    ../../roles/development.nix
    ../../roles/services.nix
    ../../roles/electronics.nix
    ../../roles/games.nix
  ];

  nix.useSandbox = true;

  networking = {
    hostId = "8425e349";
    hostName = "${hostName}";
  };

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

  services = {
    unifi.enable = true;

    octoprint = {
      enable = true;
      port = 8000;
    };

    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      displayManager = {
        xserverArgs = [ "-dpi 109" ];
      };
    };
  };

  users.users.octoprint.extraGroups = [ "dialout" ];

  environment = {
    etc."X11/Xresources".text = ''
      Xft.dpi: 109
    '';
  };

  system.stateVersion = "19.03";
}
