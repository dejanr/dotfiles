let
  sources = import ./sources.nix;
in
rec {
  emacs-overlay = import sources.emacs-overlay;
  home-manager = import (sources.home-manager + "/nixos");
  lib = import (sources.nixpkgs + "/lib");
  nixos = import (sources.nixpkgs + "/nixos");
  pkgs = import sources.nixpkgs;
}
