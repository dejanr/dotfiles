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
    ./nvim2
    ./tmux
    ./zsh

    # system
    ./packages

    # graphical
    ./hyprland

    # darwin
    ./darwin
  ];
}
