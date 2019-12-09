{ config, lib, pkgs, ... }:

let
  hostName = "pocket";
  fancontrol = import ./fancontrol.nix {};
in {
  imports =
    [
    ./hardware-configuration.nix
    ../../roles/common.nix
    ../../roles/shells/zsh
    ../../roles/fonts.nix
    ../../roles/multimedia.nix
    ../../roles/desktop.nix
    ../../roles/i3.nix
    ../../roles/development.nix
    ../../roles/services.nix
    ../../roles/electronics.nix
    ../../roles/email-client.nix
   ];

  nix.useSandbox = false;

  networking = {
    hostName = hostName;
    hostId = "efc96a34";
  };

  services = {
    xserver = {
      enable = true;

      xrandrHeads = [
        {
          output = "eDP-1";
          primary = true;
          monitorConfig = ''
            Option "Rotate" "right"
          '';

        }
      ];

    };

    tlp = {
      enable = true;
      extraConfig = ''
      '';
    };
  };

  environment = {
    etc."X11/Xresources".text = ''
      Xft.dpi: 200
    '';
  };

  programs.light.enable = true;

  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";
#
#  systemd.services.fancontrol = {
#    description = "Start fancontrol";
#    wantedBy = [ "multi-user.target" ];
#    serviceConfig = {
#      Type = "simple";
#      ExecStart = "${pkgs.lm_sensors}/sbin/fancontrol";
#    };
#  };
#
#  systemd.services.fancontrolRestart = {
#    description = "Restart fancontrol on resume";
#    wantedBy = [ "suspend.target" ];
#    after = [ "suspend.target" ];
#    serviceConfig = {
#      Type = "simple";
#      ExecStart = "${pkgs.systemd}/bin/systemctl --no-block restart fancontrol";
#    };
#  };
#
#  environment.etc."fancontrol".text = fancontrol;

  system.stateVersion = "19.03";
}
