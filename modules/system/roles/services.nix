{ config, lib, pkgs, ... }:

{
  services.mullvad-vpn.enable = true;

  services = {
    localtimed.enable = true;

    flatpak.enable = true;

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
    avahi.nssmdns = true;
    urxvtd.enable = true;

    mpd.enable = true;
    udisks2.enable = true;

    fail2ban = {
      enable = true;
      jails = {
        # this is predefined
        ssh-iptables = ''
          enabled  = true
        '';
      };
    };

    openssh = {
      enable = true;
      permitRootLogin = "yes";
      passwordAuthentication = false;
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

    zerotierone.enable = true;
    zerotierone.joinNetworks = [ "17d709436c300cfe" ];

    accounts-daemon.enable = true;
  };
}
