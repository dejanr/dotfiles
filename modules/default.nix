{ lib, stdenv, ... }:

{
  home.stateVersion = "23.11";

  imports = [
    ./common/secrets.nix

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

    # graphical
    ./hyprland

    # darwin
    ./darwin
  ];
}
