{ lib, stdenv, inputs, pkgs, ... }:

{
  home.stateVersion = "23.11";

  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
  };

  nix.settings = {
    experimental-features = "nix-command flakes";
    nix-path = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
  };

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
