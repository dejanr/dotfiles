{ config, pkgs, ... }:

{
  fileSystems."/mnt/home" = {
    device = "192.168.1.111:/home";
    fsType = "nfs";
    options = [ "nofail" ];
  };
  fileSystems."/mnt/media" = {
    device = "192.168.1.111:/media";
    fsType = "nfs";
    options = [ "nofail" ];
  };
  fileSystems."/mnt/projects" = {
    device = "192.168.1.111:/projects";
    fsType = "nfs";
    options = [ "nofail" ];
  };
}
