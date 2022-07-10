{ config, lib, inputs, ... }:

{
  imports = [ ../../modules/default.nix ];

  config.modules = {
    # gui

    # cli
    git.enable = true;
    bash.enable = true;
    tmux.enable = true;

    # system
  };
}
