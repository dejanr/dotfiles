{
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  security.pki.certificateFiles = [
    ./caddy-local-root.crt
  ];

  virtualisation.podman.enable = true;

  environment.systemPackages = [
    pkgs.comfy-model
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

    comfyui = {
      enable = true;
      cuda = true;
      package = pkgs.comfy-ui-cuda-wrapped;
      enableManager = true;
      user = "dejanr";
      group = "users";
      createUser = false;
      dataDir = "/home/dejanr/.config/comfy-ui";
      listenAddress = "127.0.0.1";
      port = 8188;
      environment = {
        PYTHONPATH = "${pkgs.python312Packages."rotary-embedding-torch"}/${pkgs.python312.sitePackages}";
        AUX_ANNOTATOR_CKPTS_PATH = "/home/dejanr/.config/comfy-ui/models/annotators";
        AUX_USE_SYMLINKS = "false";
      };
      customNodes = {
        ComfyUI-SeedVR2_VideoUpscaler = pkgs.fetchFromGitHub {
          owner = "numz";
          repo = "ComfyUI-SeedVR2_VideoUpscaler";
          rev = "4490bd1f482e026674543386bb2a4d176da245b9";
          hash = "sha256-6nsqFflLw9vYH/du35ET46fdAm1NMjjTe2bA8JmaBE4=";
        };
        comfyui_controlnet_aux = pkgs.fetchFromGitHub {
          owner = "Fannovel16";
          repo = "comfyui_controlnet_aux";
          rev = "95a13e2e5d8f8ae57583fbebb0be1f670889858b";
          hash = "sha256-5ZyU+mqxNTb/Gl+x5htFeYuI148niW0VIzvt0p60r+4=";
        };
        rgthree-comfy = pkgs.fetchFromGitHub {
          owner = "rgthree";
          repo = "rgthree-comfy";
          rev = "8ff50e4521881eca1fe26aec9615fc9362474931";
          hash = "sha256-MueLFV5gaK6vPI0BEPxL3ZueOK2eFcZzajLyo95HrOE=";
        };
        ComfyUI-GGUF = pkgs.fetchFromGitHub {
          owner = "city96";
          repo = "ComfyUI-GGUF";
          rev = "6ea2651e7df66d7585f6ffee804b20e92fb38b8a";
          hash = "sha256-/ZwecgxTTMo9J1whdEJci8lEkOy/yP+UmjbpOAA3BvU=";
        };
        PuLID_ComfyUI = pkgs.fetchFromGitHub {
          owner = "cubiq";
          repo = "PuLID_ComfyUI";
          rev = "93e0c4c226b87b23c0009d671978bad0e77289ff";
          hash = "sha256-gzAqb8rNIKBOR41tPWMM1kUoKOQTOHtPIdS0Uv1Keac=";
        };
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
      extraUpFlags = [ "--ssh" ];
      extraSetFlags = [ "--advertise-exit-node" ];
    };

    github-runners.dejli = {
      enable = true;
      replace = true;
      url = "https://github.com/dejli/dejli";
      tokenFile = "/run/agenix/github_runner_token_dejli";
      user = "github-runner";
      group = "github-runner";
      extraLabels = [ "nix" ];
      extraPackages = with pkgs; [
        nix
        nodejs
        pnpm
        git
      ];
      serviceOverrides = {
        TimeoutStartSec = "5min";
        Restart = lib.mkForce "on-failure";
        RestartSec = "15s";
      };
    };
  };


  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 22 ];

  users.groups.github-runner = { };
  users.users.github-runner = {
    isSystemUser = true;
    group = "github-runner";
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
