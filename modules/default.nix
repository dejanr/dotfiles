{ ... }:

{
  home.stateVersion = "23.05";

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
