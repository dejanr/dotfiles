{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/home/apps/kitty.nix
    ../../modules/home/cli/direnv.nix
    ../../modules/home/cli/git.nix
    ../../modules/home/cli/tmux.nix
    ../../modules/home/cli/nvim.nix
    ../../modules/home/cli/zsh.nix
    ../../modules/darwin/gui/aerospace.nix
  ];

  config.modules = {
    # apps
    apps.kitty.enable = true;

    # cli
    home.cli.direnv.enable = true;
    home.cli.git.enable = true;
    home.cli.nvim.enable = true;
    home.cli.tmux.enable = true;
    home.cli.zsh.enable = true;

    # darwin
  };

  config.home.stateVersion = "23.11";
}
