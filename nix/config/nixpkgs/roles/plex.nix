{ config, lib, boot, networking, containers, pkgs, ... }:

{
  networking.firewall.allowedTCPPorts = [ 32400 ];

  fileSystems."/var/lib/plex" = {
    device = "zpool/root/config/plex";
    fsType = "zfs";
  };

  containers.plex = {
    autoStart = true;

    bindMounts = {
      "/var/lib/plex" = {
        hostPath = "/var/lib/plex";
        isReadOnly = false;
      };
      "/downloads" = {
        hostPath = "/home/dejanr/downloads";
        isReadOnly = false;
      };
    };

    config = {
      boot.isContainer = true;

      networking.hostName = "plex";
      networking.firewall.enable = false;
      networking.interfaces.eth0.useDHCP = true;

      nixpkgs.config.allowUnfree = true;

      services.plex = {
        enable = true;
        dataDir = "/var/lib/plex";
      };
    };
  };
}
