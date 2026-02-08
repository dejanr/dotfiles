{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  virtualisation.podman.enable = true;

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
        LocalForward 3000 localhost:3000
        LocalForward 8080 localhost:8080
        LocalForward 8090 localhost:8090
        LocalForward 4000 localhost:4000
        LocalForward 4001 localhost:4001
        LocalForward 6006 localhost:6006
  '';

  age.secrets.github_runner_token_dejli.file = ../../secrets/github_runner_token_dejli.age;

  nix.settings.trusted-users = [ "github-runner-dejli" ];

  services = {
    caddy = {
      enable = true;
      virtualHosts = {
        "dej.li.dev" = {
          extraConfig = ''
            tls internal
            handle /auth/* {
              reverse_proxy localhost:3001
            }
            handle /api/* {
              reverse_proxy localhost:3002
            }
            handle {
              reverse_proxy localhost:3000
            }
          '';
        };
        "dejan.ranisavljevic.com.dev" = {
          extraConfig = ''
            tls internal
            reverse_proxy localhost:3003
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
      extraLabels = [ "nix" ];
      extraPackages = with pkgs; [
        nix
        nodejs
        pnpm
        git
      ];
    };
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
}
