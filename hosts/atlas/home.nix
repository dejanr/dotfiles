{ pkgs, ... }:

{
  imports = [ ../../modules/default.nix ];

  config.modules = {
    # gui
    kitty.enable = true;
    kitty.fontSize = "14.0";

    # cli
    direnv.enable = true;
    git.enable = true;
    nvim.enable = true;
    tmux.enable = true;
    zsh.enable = true;

    # system
    packages.enable = true;
  };
}
