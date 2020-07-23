{ config, pkgs, ... }:

{ config, options, pkgs, lib, ... }:
with lib;
{
  options.modules.services.ssh = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.services.ssh.enable {
    services.openssh = {
      enable = true;
      forwardX11 = true;
      permitRootLogin = "no";
      passwordAuthentication = false;

      # Allow local LAN to connect with passwords
      extraConfig = ''
        Match address 192.168.0.0/24
        PasswordAuthentication yes
      '';
    };

    users.users.dejanr.openssh.authorizedKeys.keys = [
    ];
  };
}
