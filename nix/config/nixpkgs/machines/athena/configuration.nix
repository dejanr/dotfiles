{ config, lib, pkgs, ... }:
let
  hostName = "athena";
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../roles/common.nix
      ../../roles/shells/bash
      ../../roles/fonts.nix
      ../../roles/multimedia.nix
      ../../roles/desktop.nix
      ../../roles/i3.nix
      ../../roles/development.nix
    ];

  nix.useSandbox = true;

  networking = {
    hostName = hostName;
    hostId = "8425e349";
  };

  services = {
    xserver = {
      enable = true;
      useGlamor = true;
      videoDrivers = [ "amdgpu" ];

      displayManager = {
        xserverArgs = [ "-dpi 109" ];
      };
    };

    tlp = {
      enable = true;
    };

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
    };

    postfix = {
      enable = true;
      setSendmail = true;
    };

    upower.enable = true;
    chrony.enable = true;
  };

  environment = {
    etc."X11/Xresources".text = ''
      Xft.dpi: 109
    '';

    systemPackages = with pkgs; [
      libgphoto2 # A library for accessing digital cameras
      gphoto2 # A ready to use set of digital camera software applications
      gphoto2fs # mount camera as fs
    ];
  };

  fonts.fontconfig.dpi = 109;

  programs.light.enable = true;

  system.stateVersion = "20.09";
}
