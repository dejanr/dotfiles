{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    nix-gaming.url = "github:fufexan/nix-gaming";
    mach-nix.url = "github:DavHau/mach-nix";
  };

  outputs = { home-manager, nixpkgs, nur, nix-gaming, mach-nix, ... }@inputs:
    let
      system = "x86_64-linux"; # current system
      pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
      lib = nixpkgs.lib;
      overlays = let paths = [ ./overlays ];
      in with builtins;
      concatMap (path:
        (map (n: import (path + ("/" + n))) (filter (n:
          match ".*\\.nix" n != null
          || pathExists (path + ("/" + n + "/default.nix")))
          (attrNames (readDir path))))) paths ++ [ nur.overlay ];

      mkSystem = pkgs: system: hostname:
        pkgs.lib.nixosSystem {
          system = system;
          modules = [
            { networking.hostName = hostname; }
            ./modules/system/configuration.nix
            (./. + "/hosts/${hostname}/hardware-configuration.nix")
            (./. + "/hosts/${hostname}/configuration.nix")
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useUserPackages = true;
                useGlobalPkgs = true;
                extraSpecialArgs = { inherit inputs system; };
                users.dejanr.imports = [
                    (./. + "/hosts/${hostname}/home.nix")
                ];
              };
              nixpkgs.overlays = [nur.overlay] ++ overlays;
            }
          ];
          specialArgs = { inherit inputs; };
        };

    in {
      nixosConfigurations = {
        alpha = mkSystem inputs.nixpkgs "x86_64-linux" "alpha";
        omega = mkSystem inputs.nixpkgs "x86_64-linux" "omega";
        theory = mkSystem inputs.nixpkgs "aarch64-linux" "theory";
        vm = mkSystem inputs.nixpkgs "x86_64-linux" "vm";
      };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      devShells.x86_64-linux.default = pkgs.callPackage ./shell.nix { };
    };
}
