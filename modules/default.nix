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

  imports =
    let
      # Get all modules from category directories
      moduleDir = ./.;
      categories = [ "secrets" "gui" "cli" "system" ];

      getModulesFromCategory = category:
        let
          categoryPath = moduleDir + "/${category}";
          categoryExists = builtins.pathExists categoryPath;
        in
        if categoryExists then
          let
            moduleDirs = builtins.attrNames (lib.filterAttrs
              (name: type:
                type == "directory" &&
                builtins.pathExists (categoryPath + "/${name}/default.nix")
              )
              (builtins.readDir categoryPath));
          in
          map (name: categoryPath + "/${name}") moduleDirs
        else [ ];
    in
    builtins.concatLists (map getModulesFromCategory categories);
}
