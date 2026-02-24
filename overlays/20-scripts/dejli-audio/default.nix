{ pkgs }:

let
  name = "dejli-audio";
  source = import ./script.nix {
    inherit pkgs;
  };
in
pkgs.writeShellScriptBin name source
