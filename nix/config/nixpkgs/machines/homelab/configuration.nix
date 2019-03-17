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

  nix.useSandbox = true;
  nix.binaryCaches = [ https://cache.nixos.org ];
  nix.trustedUsers = [ "${username}" "root" ];

  networking = {
    hostId = "8425e349";
    hostName = "homelab";
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = [ pkgs.vaapiIntel pkgs.libvdpau-va-gl pkgs.vaapiVdpau ];
    };
    pulseaudio.support32Bit = true;
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
