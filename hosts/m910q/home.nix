{ config, lib, inputs, ... }:

{
  imports = [ ../../modules/default.nix ];

  config.modules = {
    # gui

    # cli
    git.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    nvim.enable = true;
    direnv.enable = true;

    # system
    packages.enable = true;
  };
}
