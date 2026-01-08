let
  pkgs = import <nixpkgs> { };
  pi-mono-src = fetchGit {
    url = "https://github.com/badlogic/pi-mono";
    ref = "main";
  };
  piMono = import ../../nix/package.nix { inherit pkgs pi-mono-src; };
in
import ./nix/package.nix { inherit pkgs piMono; }
