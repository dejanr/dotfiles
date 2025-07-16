{
  lib,
  stdenv,
  inputs,
  pkgs,
  importsFrom,
  ...
}:

{
  home.stateVersion = "23.11";

  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
  };

  nix.settings = {
    experimental-features = "nix-command flakes";
    nix-path = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
  };

  imports = importsFrom {
    path = ./.;
    exclude = [ "config.nix" ];
  };
}
