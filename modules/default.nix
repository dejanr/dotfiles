{ inputs, pkgs, config, ... }:

{
  home.stateVersion = "21.03";
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
