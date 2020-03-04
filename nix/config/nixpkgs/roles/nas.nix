{ config, pkgs, ... }:

{
  fileSystems."/home/dejanr/sync/inbox" = {
    device = "10.147.17.100:/volume1/inbox";
    fsType = "nfs";
  };

  fileSystems."/home/dejanr/sync/storage" = {
    device = "10.147.17.100:/volume1/storage";
    fsType = "nfs";
  };

  fileSystems."/home/dejanr/sync/users" = {
    device = "10.147.17.100:/volume1/users";
    fsType = "nfs";
  };
}
