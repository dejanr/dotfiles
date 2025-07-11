{ config, lib, inputs, ... }:

{
  imports = [ ../../modules/home/default.nix ];

  config.modules = {
    # secrets
    home.secrets.agenix.enable = true;

    # cli
    home.cli.git.enable = true;
    home.cli.zsh.enable = true;
    home.cli.tmux.enable = true;
    home.cli.nvim.enable = true;
    home.cli.direnv.enable = true;

    # system
    home.common.packages.enable = true;
  };
}
