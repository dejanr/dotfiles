{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.nixos.services.openvpn.office;
in
{
  options.modules.nixos.services.openvpn.office = {
    enable = mkEnableOption "OpenVPN office connection";

    username = mkOption {
      description = "Username for sudo rules";
      example = "dejanr";
    };
  };

  config = mkIf cfg.enable {
    services.openvpn = {
      restartAfterSleep = false;

      servers = {
        office = {
          autoStart = false;
          config = ''
            config ${config.age.secrets.openvpn_office_conf.path}
            auth-user-pass ${config.age.secrets.openvpn_office_pass.path}
          '';
          updateResolvConf = true;
          up = "${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved";
          down = "${pkgs.update-systemd-resolved}/libexec/openvpn/update-systemd-resolved";
        };
      };
    };

    security.sudo.extraRules = [
      {
        users = [ cfg.username ];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl start openvpn-office.service";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl stop openvpn-office.service";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/systemctl restart openvpn-office.service";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
