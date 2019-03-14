{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    samba # The standard Windows interoperability suite of programs for Linux and Unix
  ];

  fileSystems."/export/documents" = {
    device = "/home/dejanr/documents";
    options = ["bind"];
  };

  fileSystems."/export/downloads" = {
    device = "/home/dejanr/downloads";
    options = ["bind"];
  };

  fileSystems."/export/movies" = {
    device = "/home/dejanr/movies";
    options = ["bind"];
  };

  fileSystems."/export/pictures" = {
    device = "/home/dejanr/pictures";
    options = ["bind"];
  };

  fileSystems."/export/projects" = {
    device = "/home/dejanr/projects";
    options = ["bind"];
  };

  services.nfs.server = {
    enable = true;
    # statdPort = 4000;
    # lockdPort = 4001;
    # mountdPort = 4002;
    exports = ''
      /export                192.168.1.0/24(rw,fsid=0,no_subtree_check)
      /export/documents      192.168.1.0/24(rw,async,nohide,all_squash,anonuid=1000,anongid=1000,insecure,no_subtree_check)
      /export/downloads      192.168.1.0/24(rw,async,nohide,all_squash,anonuid=1000,anongid=1000,insecure,no_subtree_check)
      /export/movies         192.168.1.0/24(rw,async,nohide,all_squash,anonuid=1000,anongid=1000,insecure,no_subtree_check)
      /export/pictures       192.168.1.0/24(rw,async,nohide,all_squash,anonuid=1000,anongid=1000,insecure,no_subtree_check)
      /export/projects       192.168.1.0/24(rw,async,nohide,all_squash,anonuid=1000,anongid=1000,insecure,no_subtree_check)
    '';
  };

  networking.firewall.allowPing = true;

  networking.firewall.allowedTCPPorts = [
    111  # nfs?
    2049 # nfs
    4000 # nfs/statd
    4001 # nfs/lockd
    4002 # nfs/mountd
    138  # smb
    445  # smb
  ];

  networking.firewall.allowedUDPPorts = [
    111  # nfs?
    2049 # nfs
    4000 # nfs/statd
    4001 # nfs/lockd
    4002 # nfs/mountd
    138  # smb
    445  # smb
  ];

  services.samba = {
    enable = true;
    syncPasswordsByPam = true;
    extraConfig = ''
      guest account = nobody
      map to guest = bad user

      load printers = no
      printing = bsd
      printcap name = /dev/null
      disable spoolss = yes

      dos charset = cp866
      unix charset = UTF8

      server multi channel support = yes
      aio read size = 1
      aio write size = 1
    '';

    shares = {
      documents = {
        path = "/home/dejanr/documents";
        "read only" = "no";
        "valid users" = "dejanr";
        "max connections" = "20000";
      };
      downloads = {
        path = "/home/dejanr/downloads";
        "read only" = "no";
        "valid users" = "dejanr";
        "max connections" = "20000";
      };
      movies = {
        path = "/home/dejanr/movies";
        "read only" = "no";
        "valid users" = "dejanr";
        "max connections" = "20000";
      };
      pictures = {
        path = "/home/dejanr/pictures";
        "read only" = "no";
        "valid users" = "dejanr";
        "max connections" = "20000";
      };
      projects = {
        path = "/mnt/projects";
        "read only" = "no";
        "valid users" = "dejanr";
        "max connections" = "20000";
      };
    };
  };
}
