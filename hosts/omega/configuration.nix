{ pkgs , lib , ... }:

let
  hostName = "omega";
in
  {
    imports = [
      ../../modules/system/roles/fonts.nix
      ../../modules/system/roles/desktop.nix
      ../../modules/system/roles/multimedia.nix
      ../../modules/system/roles/i3.nix
      ../../modules/system/roles/services.nix
      ../../modules/system/roles/development.nix
      ../../modules/system/roles/games.nix
      ../../modules/system/roles/virtualisation.nix
    ];

    networking = {
      hostId = "8425e349";
      hostName = "${hostName}";
    };

    services = {
      xserver = {
        enable = true;
        videoDrivers = [ "nvidia" ];

        displayManager = {
          xserverArgs = [ "-dpi 109" ];
        };

        deviceSection = ''
          Option "AccelMethod" "glamor"
          Option "DRI" "3"
          Option "TearFree" "on"
          Option "ColorTiling" "on"
          Option "ColorTiling2D" "on"
        '';
      };

      tlp = {
        enable = true;
        settings = {
          CPU_SCALING_GOVERNOR_ON_AC = "performance";
          CPU_SCALING_GOVERNOR_ON_BAT = "ondemand";
          SCHED_POWERSAVE_ON_AC = 0;
          SCHED_POWERSAVE_ON_BAT = 1;
          ENERGY_PERF_POLICY_ON_AC = "performance";
          ENERGY_PERF_POLICY_ON_BAT = "powersave";
          PCIE_ASPM_ON_AC = "performance";
          PCIE_ASPM_ON_BAT = "powersave";
          WIFI_PWR_ON_AC = 1;
          WIFI_PWR_ON_BAT = 5;
          RUNTIME_PM_ON_AC = "on";
          RUNTIME_PM_ON_BAT = "auto";
          USB_BLACKLIST_WWAN = 1;
          SOUND_POWER_SAVE_ON_BAT = 0;
          USB_AUTOSUSPEND = 0;
          CONTROL_USB_AUTOSUSPEND = "off";
          DEVICES_TO_DISABLE_ON_STARTUP = "";
        };
      };

      tailscale = {
        enable = true;
        useRoutingFeatures = "both";
        extraUpFlags = ["--ssh"];
      };
    };

    environment = {
      etc."X11/Xresources".text = ''
        Xft.dpi: 109
      '';
      systemPackages = [ ];
    };

    system.stateVersion = "23.05";
  }
