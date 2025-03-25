{ pkgs, config, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/roles/fonts.nix
    ../../modules/system/roles/desktop.nix
    ../../modules/system/roles/multimedia.nix
    ../../modules/system/roles/i3.nix
    ../../modules/system/roles/services.nix
    ../../modules/system/roles/development.nix
    ../../modules/system/roles/games.nix
    ../../modules/system/roles/virtualisation.nix
  ];

  networking.extraHosts =
    ''
      192.168.1.227 ot-rpi-testbed
    '';

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  nix = {
    settings = {
      trusted-public-keys = [
        "ot-nix-cache:C6ZY7QNJHk8tAcyi00y0n3UhbnZvBxJE993/J61omU4="
        "nixbuild.net/ororatech-swuerl-1:pIlkdwXcQ4rhAhyI17SLno25zgfeWFbBPBnA0jvIXyM="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };

  virtualisation.podman.enable = true;

  # sst.dev
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    bun
  ];

  # Office VPN

  services.openvpn = {
    restartAfterSleep = false;

    servers = {
      office = {
        autoStart = false;
        config = '' 
        config ${config.sops.secrets.openvpn_office_conf.path}
        auth-user-pass  ${config.sops.secrets.openvpn_office_pass.path}
      '';
        updateResolvConf = true;
        # When using resolv conf uncomment this:
        up = "${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved";
        down = "${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved";
      };
    };
  };

  security.sudo.extraRules = [
    {
      users = [ "dejanr" ];
      commands = [
        { command = "/run/current-system/sw/bin/systemctl start openvpn-office.service"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl stop openvpn-office.service"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/systemctl restart openvpn-office.service"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];
}
