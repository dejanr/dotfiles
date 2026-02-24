{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  virtualisation.podman.enable = true;

  environment.systemPackages = with pkgs; [
    # comfy-model
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

  age.secrets.github_runner_token_dejli.file = ../../secrets/github_runner_token_dejli.age;

  nix.settings.trusted-users = [ "github-runner" ];

  services = {
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
        "comfyui.dev" = {
          extraConfig = ''
            tls internal
            reverse_proxy localhost:8188
          '';
        };
      };
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "both";
      extraUpFlags = [ "--ssh" "--operator=dejanr" ];
      extraSetFlags = [ "--advertise-exit-node" ];
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

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

  programs.niri = {
    enable = true;
    useNautilus = false;
  };

  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      target = "niri.service";
    };
    plugins = {
      DejliAudioStatus.src = ./config/dms/plugins/DejliAudioStatus;
      DejliGifStatus.src = ./config/dms/plugins/DejliGifStatus;
      DejliScreenshotAction.src = ./config/dms/plugins/DejliScreenshotAction;
      Tailscale.src = ./config/dms/plugins/Tailscale;
    };
  };

  services.greetd = {
    enable = true;
    settings = {
      initial_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "dejanr";
      };
      default_session = {
        command = "${pkgs.niri}/bin/niri-session";
        user = "dejanr";
      };
    };
  };

  services.power-profiles-daemon.enable = lib.mkForce false;
  services.gnome.gcr-ssh-agent.enable = lib.mkForce false;

  modules.nixos = {
    roles = {
      hosts.enable = true;
      dev.enable = true;
      desktop.enable = true;
      games.enable = true;
      multimedia.enable = true;
      services.enable = true;
    };
  };
}
