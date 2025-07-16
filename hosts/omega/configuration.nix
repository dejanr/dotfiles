{
  pkgs,
  config,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.extraHosts = ''
    192.168.1.227 ot-rpi-testbed
  '';

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  virtualisation.podman.enable = true;

  # sst.dev
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    bun
  ];

  programs.ssh.extraConfig = ''
    Host dsn-gw
        Hostname gw.dsn.orora.tech
        Port 30100
        User dejan.ranisavljevic
        IdentityFile /home/dejanr/.ssh/id_ed25519
    Host nix-cache
        User nix-cache
        Hostname iron-nugget.srv.orora.tech
        Port 22222
        ProxyJump dsn-gw
        IdentityFile /home/dejanr/.ssh/id_ed25519
  '';

  # Office VPN

  modules.nixos = {
    roles = {
      desktop.enable = true;
      dev.enable = true;
      games.enable = true;
      hosts.enable = true;
      i3.enable = true;
      multimedia.enable = true;
      services.enable = true;
      virtualisation.enable = true;
    };

    services.openvpn.office = {
      enable = true;
      username = "dejanr";
    };
  };
}
