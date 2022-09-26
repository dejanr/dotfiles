{ inputs, pkgs, config, ... }:

{
  home.stateVersion = "21.05";

  imports = [
    # gui

    # cli
    ./bash
    ./tmux
    #./vim
    ./git

    # system
  ];
}
