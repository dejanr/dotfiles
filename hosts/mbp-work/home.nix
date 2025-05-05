{ config, lib, inputs, pkgs, ... }:

{
  imports = [ ../../modules/default.nix ];

  config.modules = {
    # gui
    kitty.enable = true;

    # cli
    direnv.enable = true;
    git.enable = true;
    nvim.enable = true;
    tmux.enable = true;
    zsh.enable = true;

    # darwin

    # system
    packages.enable = true;
  };
}
