{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  virtualisation.podman.enable = true;

  nixpkgs.config = {
    cudaCapabilities = [ "8.6" ];
    cudaForwardCompat = false;
  };

  systemd.services.nvidia-power-limit = {
    description = "Set NVIDIA GPU power limit";
    after = [ "systemd-modules-load.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.hardware.nvidia.package.bin ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      nvidia-smi -pm 1
      nvidia-smi -pl 380
    '';
  };

  systemd.services."lg-tv-input@" = {
    description = "Switch LG TV input to %i";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig = {
      StartLimitBurst = 8;
      StartLimitIntervalSec = "30s";
    };
    serviceConfig = {
      Type = "oneshot";
      Restart = "on-failure";
      RestartSec = "2s";
      StateDirectory = "lg-tv-input";
      StateDirectoryMode = "0700";
      Environment = "LG_TV_INPUT_KEY_FILE=/var/lib/lg-tv-input/client-key.json";
      ExecStart = "${pkgs.lg-tv-input}/bin/lg-tv-input --host 192.168.1.178 %i";
    };
  };

  environment.systemPackages = [
    pkgs.lg-tv-input
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
    xserver.displayManager.autoLogin.user = "dejanr";
    flatpak.enable = true;

    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="1209", ATTR{idProduct}=="2303", RUN+="${config.systemd.package}/bin/systemctl --no-block start lg-tv-input@HDMI_1.service"
      ACTION=="remove", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ENV{PRODUCT}=="1209/2303/*", RUN+="${config.systemd.package}/bin/systemctl --no-block start lg-tv-input@HDMI_3.service"
    '';

    openssh = {
      openFirewall = false;
      settings = {
        AllowUsers = [ "dejanr" ];
      };
    };

    caddy = {
      enable = true;
      virtualHosts = {
        "dej.li.dev" = {
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
        "dejan.ranisavljevic.com.dev" = {
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
      extraUpFlags = [ "--ssh" ];
      extraSetFlags = [ "--advertise-exit-node" ];
    };

    sunshine = {
      enable = false;
      openFirewall = false;
      capSysAdmin = true;
      settings = {
        upnp = "off";
        origin_web_ui_allowed = "lan";
        origin_pin_allowed = "lan";
      };
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

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      22
      8181
      47984
      47989
      47990
      48010
    ];
    allowedUDPPorts = [
      47998
      47999
      48000
      48002
      48010
    ];
  };

  # Set RØDE VideoMic Me-C+ as default mic
  services.pipewire.wireplumber.extraConfig."10-default-source" = {
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

  modules.nixos = {
    roles = {
      hosts.enable = true;
      dev.enable = true;
      i3.enable = true;
      desktop.enable = true;
      games.enable = true;
      multimedia.enable = true;
      services.enable = true;
      virtualisation.enable = true;
    };
  };

  users.users.dejanr.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJUqC/zpHXN8XkBVnvxG5oJyXqoKSvdXhNP7xyj1JvCA iphone"

  ];
}
