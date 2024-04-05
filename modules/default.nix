{ lib, stdenv, ... }:

{
  home.stateVersion = "23.11";

  imports = [
    # gui
    ./alacritty
    ./kitty

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
