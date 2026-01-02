{
  config,
  lib,
  inputs,
  ...
}:

{
  imports = [ ../../modules/home/default.nix ];

  config.modules = {
    home.cli.git.enable = true;
    home.cli.zsh.enable = true;
    home.cli.tmux.enable = true;
    home.cli.nixvim.enable = true;
    home.cli.direnv.enable = true;

    # system
    home.common.packages.enable = true;
  };
}
