{ ... }:

{
  home.stateVersion = "23.05";

  imports = [
    # gui

    # cli
    ./bash
    ./direnv
    ./git
    ./nvim
    ./tmux
    ./zsh

    # system
    ./packages
  ];
}
