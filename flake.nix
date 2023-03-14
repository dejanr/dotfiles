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
            (./. + "/hosts/${hostname}/hardware-configuration.nix")
            ./modules/system/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useUserPackages = true;
                useGlobalPkgs = true;
                extraSpecialArgs = { inherit inputs; };
                users.dejanr = (./. + "/hosts/${hostname}/home.nix");
              };
              nixpkgs.overlays = overlays;
            }

          ];
          specialArgs = { inherit inputs; };
        };

    in {
      nixosConfigurations = {
        omega = mkSystem inputs.nixpkgs "x86_64-linux" "omega";
      };
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt;
      devShells.x86_64-linux.default = pkgs.callPackage ./shell.nix { };
    };
}
