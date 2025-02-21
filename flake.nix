{
  description = "NixOS configuration";

  inputs = {

    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = { url = "github:nix-community/NUR"; };

    nix-gaming.url = "github:fufexan/nix-gaming";
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      flake = false;
    };

    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
    nixos-apple-silicon.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:danth/stylix";

    nightfox = {
      url = "github:EdenEast/nightfox.nvim";
      flake = false;
    };

    browser-previews = {
      url = "github:nix-community/browser-previews";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , home-manager
    , nix-darwin
    , nixos-apple-silicon
    , nixpkgs
    , nur
    , nix-gaming
    , rust-overlay
    , stylix
    , sops-nix
    , ...
    }@inputs:

    let
      inherit (self) outputs;
      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forEachPkgs = f: forEachSystem (sys: f nixpkgs.legacyPackages.${sys});
      overlays =
        let paths = [ ./overlays ];
        in builtins.concatMap
          (path:
            (map (n: import (path + ("/" + n))) (builtins.filter
              (n:
                builtins.match ".*\\.nix" n != null
                || builtins.pathExists (path + ("/" + n + "/default.nix")))
              (builtins.attrNames (builtins.readDir path)))))
          paths;
      mkSystem = pkgs: system: hostname:
        pkgs.lib.nixosSystem {
          system = system;
          modules = [
            {
              networking.hostName = hostname;
              networking.timeServers = [ "1.amazon.pool.ntp.org" "2.amazon.pool.ntp.org" "3.amazon.pool.ntp.org" ];
            }
            stylix.nixosModules.stylix
            nur.modules.nixos.default
            sops-nix.nixosModules.sops
            ./modules/system/configuration.nix
            (./. + "/hosts/${hostname}/hardware-configuration.nix")
            (./. + "/hosts/${hostname}/configuration.nix")
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useUserPackages = true;
                useGlobalPkgs = true;
                extraSpecialArgs = { inherit inputs system; };
                users.dejanr.imports =
                  [ (./. + "/hosts/${hostname}/home.nix") ];
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                ];
              };
              nixpkgs.overlays = [
                (import rust-overlay)
                nixos-apple-silicon.overlays.apple-silicon-overlay
                nixos-apple-silicon.overlays.default
                nur.overlays.default
              ] ++ overlays;
            }
          ];
          specialArgs = { inherit inputs; };
        };

    in
    {
      formatter = forEachPkgs (pkgs: pkgs.nixpkgs-fmt);
      devShells = forEachPkgs (pkgs: import ./shell.nix { inherit pkgs; });
      nixosConfigurations = {
        alpha = mkSystem inputs.nixpkgs "x86_64-linux" "alpha";
        atlas = mkSystem inputs.nixpkgs "x86_64-linux" "atlas";
        omega = mkSystem inputs.nixpkgs "x86_64-linux" "omega";
        theory = mkSystem inputs.nixpkgs "aarch64-linux" "theory";
        vm = mkSystem inputs.nixpkgs "x86_64-linux" "vm";
      };
      darwinConfigurations =
        let
          username = "dejan.ranisavljevic";
          system = "aarch64-darwin";
        in
        {
          "mbp-work" = nix-darwin.lib.darwinSystem {
            inherit system;
            specialArgs = { inherit inputs system; };
            modules = [
              ./hosts/mbp-work/configuration.nix
              home-manager.darwinModules.home-manager
              {
                users.users.${username}.home = "/Users/${username}";
                home-manager = {
                  useUserPackages = true;
                  useGlobalPkgs = true;
                  extraSpecialArgs = { inherit inputs system; };
                  users.${username}.imports =
                    [ (./. + "/hosts/mbp-work/home.nix") ];
                };
                nixpkgs.overlays = [ nur.overlays.default ] ++ overlays;
              }
            ];
          };
        };
    };
}
