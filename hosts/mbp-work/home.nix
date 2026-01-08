{
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home/default.nix
    ../../modules/darwin/gui/aerospace.nix
  ];

  config.programs.bun.enable = true;
  config.home.packages = [
    pkgs.slack
    pkgs.tailscale
    pkgs.raycast
    pkgs.llama-cpp
    pkgs.opencode
  ];

  config.modules = {
    home.common.packages.enable = true;

    # apps
    apps.kitty.enable = true;

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
}
