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
    settings.options.urAccepted = -1;
  };

  config.modules = {
    home.common.packages.enable = true;

    # apps
    apps.kitty.enable = true;
    apps.obsidian.enable = true;

    # secrets
    home.secrets.agenix.enable = true;

    # cli
    home.cli.direnv.enable = true;
    home.cli.dev.enable = true;
    home.cli.git.enable = true;
    home.cli.nixvim.enable = true;
    home.cli.opencode.enable = true;
    home.cli.pi-mono.enable = true;
    home.cli.tmux.enable = true;
    home.cli.zsh.enable = true;

    # darwin
    darwin.gui.aerospace.enable = true;
  };

  config.home.stylix.theme = "catppuccin-mocha";
}
