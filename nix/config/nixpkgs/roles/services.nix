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

    tlp = {
      enable = true;
      extraConfig = ''
        CPU_SCALING_GOVERNOR_ON_AC=performance
        CPU_SCALING_GOVERNOR_ON_BAT=ondemand
        SCHED_POWERSAVE_ON_AC=0
        SCHED_POWERSAVE_ON_BAT=1
        ENERGY_PERF_POLICY_ON_AC=performance
        ENERGY_PERF_POLICY_ON_BAT=powersave
        PCIE_ASPM_ON_AC=performance
        PCIE_ASPM_ON_BAT=powersave
        WIFI_PWR_ON_AC=1
        WIFI_PWR_ON_BAT=5
        RUNTIME_PM_ON_AC=on
        RUNTIME_PM_ON_BAT=auto
        USB_AUTOSUSPEND=0
        USB_BLACKLIST_WWAN=1
        DEVICES_TO_DISABLE_ON_STARTUP="bluetooth"
        SOUND_POWER_SAVE_ON_BAT=0
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
