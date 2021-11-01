{ config, lib, pkgs, ... }:

#
# Omega
#

let
  hostName = "omega";
in
  {
    imports = [
      ./hardware-configuration.nix
      ../../roles/common.nix
      ../../roles/hosts.nix
    ];

    networking = {
      hostId = "8425e349";
      hostName = "${hostName}";
    };

    system.stateVersion = "21.05";
  }
