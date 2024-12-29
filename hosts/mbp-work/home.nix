{ config, lib, inputs, pkgs, ... }:

{
  imports = [ ../../modules/default.nix ];

  config.modules = {
    # gui
    kitty.enable = true;

    # cli
    direnv.enable = true;
    git.enable = true;
    nvim2.enable = true;
    tmux.enable = true;
    zsh.enable = true;

    # darwin
    darwin.sketchybar.enable = true;

    # system
    packages.enable = true;
  };
}
