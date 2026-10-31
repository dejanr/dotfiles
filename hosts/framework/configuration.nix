{
  config,
  pkgs,
  lib,
  ...
}:

let
  home = config.home-manager.users.dejanr;
  greeterConfig = import ./config/dms/greeter.nix {
    inherit pkgs;
    preferences = home.programs.dank-material-shell.settings;
    wallpaper = home.modules.home.gui.dms.sessionPreferences.wallpaperPath;
  };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.kernelParams = lib.optional config.home-manager.users.dejanr.modules.home.cli.halogen.enable "zfs.zfs_arc_max=8589934592";

  environment.systemPackages = with pkgs; [
    xwayland-satellite
    wl-clipboard
  ];

  # sst.dev
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    bun
  ];
  programs.mosh.enable = true;

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "dejanr" ];
  };

  programs.ssh.extraConfig = ''
    Host dsn-gw
        Hostname gw.dsn.orora.tech
        Port 30100
        User dejan.ranisavljevic
        IdentityFile /home/dejanr/.ssh/id_ed25519_old
    Host nix-cache
        User nix-cache
        Hostname iron-nugget.srv.orora.tech
        Port 22222
        ProxyJump dsn-gw
        IdentityFile /home/dejanr/.ssh/id_ed25519
    Host dejli
        Hostname dejli
        User dejanr
  '';

  services = {
    printing.enable = lib.mkForce false;
    flatpak.enable = true;

    openssh = {
      openFirewall = false;
      settings = {
        AllowUsers = [ "dejanr" ];
      };
    };

    caddy = {
      enable = true;
      globalConfig = ''
        http_port 43080
      '';
      virtualHosts = {
        "dej.li.dev:43443" = {
          extraConfig = ''
            tls internal
            handle /swagger {
              redir /swagger/ 308
            }
            handle_path /swagger/* {
              reverse_proxy localhost:43104
            }
            handle /api/swagger.json {
              reverse_proxy localhost:43104
            }
            handle /auth/swagger.json {
              reverse_proxy localhost:43104
            }
            handle /auth/* {
              reverse_proxy localhost:43101
            }
            handle /api/* {
              reverse_proxy localhost:43102
            }
            handle {
              reverse_proxy localhost:43100
            }
          '';
        };
        "dejan.ranisavljevic.com.dev:43443" = {
          extraConfig = ''
            tls internal
            reverse_proxy localhost:43103
          '';
        };
      };
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "both";
      extraUpFlags = [
        "--ssh"
        "--operator=dejanr"
      ];
      extraSetFlags = [ "--advertise-exit-node" ];
    };
  };

  systemd.services.flatpak-repo = {
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = [ pkgs.flatpak ];
    serviceConfig.Type = "oneshot";
    script = ''
      flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [
      22000
      21027
    ];
    interfaces.tailscale0.allowedTCPPorts = [ 22 ];
  };

  services.pipewire.wireplumber.extraConfig = {
    "10-default-source" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "node.name" = "alsa_input.usb-R__DE_R__DE_VideoMic_Me-C__A37AFAC5-00.mono-fallback"; }
          ];
          actions.update-props = {
            "priority.session" = 2500;
            "priority.driver" = 2500;
          };
        }
      ];
    };

    "10-default-sink" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "node.name" = "alsa_output.pci-0000_c2_00.1.hdmi-stereo-extra1"; }
          ];
          actions.update-props = {
            "priority.session" = 3000;
            "priority.driver" = 3000;
          };
        }
      ];
    };
  };

  programs.niri = {
    enable = true;
    useNautilus = false;
    package = pkgs.niri-release-keybinds;
  };

  programs.ydotool.enable = true;

  users.users.dejanr.uid = 1000;

  systemd.services."user@${toString config.users.users.dejanr.uid}" =
    lib.mkIf config.home-manager.users.dejanr.modules.home.cli.halogen.enable
      {
        overrideStrategy = "asDropin";
        serviceConfig.LimitMEMLOCK = "infinity";
      };

  users.users.dejanr.extraGroups = lib.mkAfter (
    [
      "ydotool"
    ]
    ++ lib.optional config.home-manager.users.dejanr.modules.home.cli.halogen.enable "render"
  );

  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      target = "niri.service";
    };
    enableDynamicTheming = false;
  };

  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configFiles = [
      "${greeterConfig}/settings.json"
      "${greeterConfig}/session.json"
    ];
  };

  services.greetd = {
    enable = true;
    settings.default_session.user = "greeter";
  };

  systemd.user.services = {
    niri.serviceConfig.ExecStartPre = "${lib.getExe config.home-manager.users.dejanr.modules.home.gui.dms.package} prepare";
    dms = {
      environment.DMS_DISABLE_MATUGEN = "1";
      serviceConfig.ExecStartPre = "${lib.getExe config.home-manager.users.dejanr.modules.home.gui.dms.package} prepare";
    };
    pipewire.unitConfig.ConditionUser = lib.mkForce "!@system";
    pipewire-pulse.unitConfig.ConditionUser = lib.mkForce "!@system";
    wireplumber.unitConfig.ConditionUser = lib.mkForce "!@system";
  };

  services.power-profiles-daemon.enable = lib.mkForce false;
  services.gnome.gcr-ssh-agent.enable = lib.mkForce false;

  modules.nixos = {
    roles = {
      ctf.enable = true;
      dev.enable = true;
      desktop.enable = true;
      games.enable = true;
      multimedia.enable = true;
      services.enable = true;
    };
  };
}
