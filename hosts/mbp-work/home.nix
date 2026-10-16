{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home/default.nix
    ../../modules/darwin/gui/aerospace.nix
  ];

  # Determinate Nix manages Nix itself; avoid adding upstream Nix to PATH.
  config.nix.enable = false;

  # Work around Home Manager's Determinate-only options.json context warning.
  # https://github.com/nix-community/home-manager/issues/7935
  config.manual.manpages.enable = false;

  config.xdg.configFile."karabiner".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hosts/mbp-work/karabiner";

  config.programs.bun.enable = true;
  config.home.packages = [
    pkgs.slack
    pkgs.tailscale
    pkgs.raycast
    pkgs.mkcert
    pkgs.nss
    pkgs.postman
    pkgs.glab
    pkgs.microsoft-rush
    pkgs.pm2
    pkgs.mongosh
    pkgs.google-cloud-sdk
  ];

  config.age.secrets.burda_sentry_cli_token.file = ../../secrets/burda_sentry_cli_token.age;
  config.programs.zsh.initContent = lib.mkAfter ''
    export SENTRY_AUTH_TOKEN=$(cat ${config.age.secrets.burda_sentry_cli_token.path})
  '';

  config.services.demo-it.enable = true;
  config.services.syncthing = {
    enable = true;
    overrideDevices = false;
    overrideFolders = false;
    settings = {
      devices.synology = {
        id = "HAVMQIE-3WREVQZ-QP7QXMO-OP353KV-275FFVH-2P3CX2D-SJZVMB2-3PL5EAP";
      };

      folders.obsidian = {
        path = "~/documents/notes/main";
        id = "data1";
        label = "Obsidian Main";
        devices = [ "synology" ];
      };

      options.urAccepted = -1;
    };
  };

  config.home.file."obsidian-syncthing-ignore" = {
    force = true;
    target = "${config.programs.obsidian.vaults.main.target}/.stignore";
    text = ''
      /.obsidian
      /reMarkable/.remarkable-sync-state.json
      (?d).DS_Store
    '';
  };

  config.modules = {
    home.common.packages.enable = true;
    home.gui.music = {
      enable = true;
      sync.enable = true;
    };

    # apps
    apps.kitty.enable = true;
    apps.obsidian.enable = true;

    # secrets
    home.secrets.agenix.enable = true;

    # cli
    home.cli.direnv.enable = true;
    home.cli.dev.enable = true;
    home.cli.git.enable = true;
    home.cli.hunk.enable = true;
    home.cli.nixvim.enable = true;
    home.cli.opencode.enable = true;
    home.cli.pi-dev.enable = true;
    home.cli.tmux.enable = true;
    home.cli.zsh.enable = true;
    home.cli.ps-kill.enable = true;

    # darwin
    darwin.gui.aerospace.enable = true;
  };

  config.home.stylix.theme = "catppuccin-mocha";
}
