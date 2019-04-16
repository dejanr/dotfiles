{ config, lib, pkgs, ... }:

{
  services = {
		printing.enable = true;
		avahi.enable = true;
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
    nixosManual.showManual = false;

    chrony.enable = true;

    postfix = {
      enable = true;
      setSendmail = true;
    };
  };
}
