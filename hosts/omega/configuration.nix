{ pkgs, config, lib, ... }:

{
  imports = [
    ../../modules/system/roles/fonts.nix
    ../../modules/system/roles/desktop.nix
    ../../modules/system/roles/multimedia.nix
    ../../modules/system/roles/i3.nix
    ../../modules/system/roles/services.nix
    ../../modules/system/roles/development.nix
    ../../modules/system/roles/games.nix
    #../../modules/system/roles/virtualisation.nix
  ];

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

  # Office VPN

  services.openvpn = {
    restartAfterSleep = false;

    servers = {
      office = {
        config = '' 
        config ${config.sops.secrets.openvpn_office_conf.path}
        auth-user-pass  ${config.sops.secrets.openvpn_office_pass.path}
      '';
        updateResolvConf = false;
        # When using resolv conf uncomment this:
        # up = "${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved";
        # down = "${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved";
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
