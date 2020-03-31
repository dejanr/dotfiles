{ lib ? (import ./nix).lib }:

with builtins; with lib;

let
  hosts = {
    home = "x86_64-linux";
    office = "x86_64-linux";
    homelab = "x86_64-linux";
    pocket = "x86_64-linux";
    theory = "x86_64-linux";
  };

  mkNixOS = name: arch:
    let
      configuration = ./nix/config/nixpkgs/machines + "/${name}/configuration.nix";
      system = arch;
      nixos = (import ./nix).nixos { inherit configuration system; };
    in nixos.config.system.build;

  mkSystem = name: arch: (mkNixOS name arch).toplevel;
  systems = mapAttrs mkSystem hosts;
  systemsWithArch = arch: mapAttrs mkSystem (filterAttrs (_:v: v == arch) hosts);
in
{
  inherit hosts;
  aarch64 = systemsWithArch "aarch64-linux";
  x86_64-linux = systemsWithArch "x86_64-linux";
} // systems
