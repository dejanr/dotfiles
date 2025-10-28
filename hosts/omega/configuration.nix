{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  systemd.user.services.sleep-inhibit = {
    description = "Inhibit automatic suspend";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.systemd}/bin/systemd-inhibit --what=handle-lid-switch:sleep:idle --why='Prevent system sleep' --mode=block sleep infinity";
      Restart = "on-failure";
    };
  };

  virtualisation.podman.enable = true;

  # sst.dev
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    bun
  ];
  programs.mosh.enable = true;

  programs.ssh.extraConfig = ''
    Host dsn-gw
        Hostname gw.dsn.orora.tech
        Port 30100
        User dejan.ranisavljevic
        IdentityFile /home/dejanr/.ssh/id_ed25519_old
    Host nix-cache
        User nix-cache
        Hostname iron-nugget.srv.orora.tech
        Port 22222
        ProxyJump dsn-gw
        IdentityFile /home/dejanr/.ssh/id_ed25519
  '';

  # Office VPN

  modules.nixos = {
    theme.enable = true;
    theme.flavor = "mocha";

    roles = {
      hosts.enable = true;
      dev.enable = true;
      i3.enable = true;
      desktop.enable = true;
      games.enable = true;
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
