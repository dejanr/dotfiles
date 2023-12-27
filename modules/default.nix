{ lib, stdenv, ... }:

{
  home.stateVersion = "23.11";

  imports = [
    # gui
    ./alacritty

    # cli
    ./bash
    ./direnv
    ./git
    ./nvim
    ./tmux
    ./zsh

    # system
    ./packages

    #
    ./darwin 
];
}
