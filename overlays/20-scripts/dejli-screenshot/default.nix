{ pkgs }:

let
  name = "dejli-screenshot";
  source = import ./script.nix {
    inherit pkgs;
  };
in
pkgs.writeShellScriptBin name source
