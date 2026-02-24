{ pkgs }:

let
  name = "dejli-gif";
  source = import ./script.nix {
    inherit pkgs;
  };
in
pkgs.writeShellScriptBin name source
