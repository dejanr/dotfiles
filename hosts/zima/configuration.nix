{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
  ];

  services = {
    fail2ban = {
      enable = true;
    };

    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
      settings.PasswordAuthentication = false;
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "both";
      extraUpFlags = [ "--ssh" ];
      extraSetFlags = [ "--advertise-exit-node" ];
    };

    postfix = {
      enable = true;
      setSendmail = true;
    };

      timesyncd.enable = true;
      timesyncd.servers = [
        "1.amazon.pool.ntp.org"
        "2.amazon.pool.ntp.org"
        "3.amazon.pool.ntp.org"
      ];
  };

  modules.nixos = {
    roles = {
      hosts.enable = true;
    };
  };
}
