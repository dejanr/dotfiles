{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  imports = [ ../../modules/home/default.nix ];

  config.programs.bun.enable = true;

  config.modules = {
    home.common.packages.enable = true;

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
