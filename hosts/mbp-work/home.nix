{ config, lib, inputs, pkgs, ... }:

{
  imports = [ ../../modules/home/default.nix ];

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

    # system
    home.common.packages.enable = true;
  };
}
