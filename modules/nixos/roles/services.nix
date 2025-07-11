{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.nixos.roles.services;

in {
  options.modules.nixos.roles.services = { enable = mkEnableOption "system services"; };

  config = mkIf cfg.enable {
  programs.ssh.startAgent = true;

  services = {
    printing.enable = true;
    printing.drivers = [ pkgs.mfc9332cdwlpr ];
    printing.browsing = true;
    printing.defaultShared = true;
    printing.extraConf = ''
      DefaultEncryption Never
    '';
    avahi.enable = true;
    avahi.publish.enable = true;
    avahi.publish.userServices = true;
    avahi.nssmdns4 = true;
    urxvtd.enable = true;

    passSecretService.enable = true;

    mpd.enable = true;
    udisks2.enable = true;

    dbus.enable = true;

    fail2ban = {
      enable = true;
    };

    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
      settings.PasswordAuthentication = false;
    };

    logind.extraConfig = ''
      HandlePowerKey=ignore
      HandleSuspendKey=ignore
      HandleHibernateKey=ignore
    '';

    acpid = {
      enable = true;

      powerEventCommands = ''
        systemctl suspend
      '';

      lidEventCommands = ''
        systemctl hibernate
      '';
    };

    upower.enable = true;

    chrony.enable = true;

    postfix = {
      enable = true;
      setSendmail = true;
    };

    accounts-daemon.enable = true;

    input-remapper.enable = true;

    resolved.enable = true;
    resolved.fallbackDns = [ "8.8.8.8" ];
    resolved.dnsovertls = "true";

    timesyncd.enable = true;
    timesyncd.servers = [ "1.amazon.pool.ntp.org" "2.amazon.pool.ntp.org" "3.amazon.pool.ntp.org" ];
    };
  };
}
