{ lib, stdenv, ... }:

{
  home.stateVersion = "23.11";

  imports = [
    # common
    ./xdg

    # secrets
    ./sops

    # gui
    ./alacritty
    ./kitty
    ./ghostty

    # cli
    ./bash
    ./direnv
    ./git
    ./nvim
    ./tmux
    ./zsh
    ./yazi

    # system
    ./packages

    # graphical
    ./hyprland

    # darwin
    ./darwin
  ];
}
