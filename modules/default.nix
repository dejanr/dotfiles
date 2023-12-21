{ ... }:

{
  home.stateVersion = "23.11";

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
