{ config, lib, inputs, pkgs, ... }:

{
  imports = [ ../../modules/default.nix ];

  config.modules = {
    # gui
    alacritty.enable = true;

    # cli
    direnv.enable = true;
    git.enable = true;
    nvim.enable = true;
    tmux.enable = true;
    zsh.enable = true;

    # darwin
    darwin.sketchybar.enable = true;

    # system
    packages.enable = true;
  };
}
