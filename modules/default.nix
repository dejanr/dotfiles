{ lib, stdenv, ... }:

{
  home.stateVersion = "23.11";

  imports = [
    # common
    ./common/secrets.nix
    #./common/xdg.nix

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
