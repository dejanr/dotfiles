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
    ./common/packages.nix
    ./common/xdg.nix
    ./secrets/agenix.nix
    ./apps/alacritty.nix
    ./apps/ghostty.nix
    ./apps/kitty.nix
    ./cli/bash.nix
    ./cli/dev.nix
    ./cli/direnv.nix
    ./cli/git.nix
    ./cli/nvim.nix
    ./cli/opencode.nix
    ./cli/tmux.nix
    ./cli/vim.nix
    ./cli/yazi.nix
    ./cli/zsh.nix
    ./gui/desktop.nix
    ./gui/games.nix
    ./gui/hyprland.nix
    ./gui/darwin/default.nix
  ];
}
