{ config, lib, pkgs, ... }:

# Omega
#

let
  hostName = "omega";
in
  {
    imports = [
      ./hardware-configuration.nix
    ];

    networking = {
      hostId = "8425e349";
      hostName = "${hostName}";
    };

    system.stateVersion = "21.05";
  }
