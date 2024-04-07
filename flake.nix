{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = { url = "github:nix-community/NUR"; };

    nix-gaming.url = "github:LunNova/nix-gaming/vkd3d-dxvk-fix";
    nix-gaming.inputs.nixpkgs.follows = "nixpkgs";

    mach-nix.url = "github:DavHau/mach-nix";
    mach-nix.inputs.nixpkgs.follows = "nixpkgs";

    vim-plugins = { url = "path:./modules/nvim/plugins"; };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      flake = false;
    };
    nixos-apple-silicon.url = "github:tpwrules/nixos-apple-silicon";
  };

  outputs =
    { self
    , home-manager
    , nix-darwin
    , nixos-apple-silicon
    , nixpkgs
    , nur
    , nix-gaming
    , mach-nix
    , vim-plugins
    , rust-overlay
    , ...
    }@inputs:

    let
      inherit (self) outputs;
      forEachSystem = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];
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
            { networking.hostName = hostname; }
            nur.nixosModules.nur
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
              };
              nixpkgs.overlays = [
                (import rust-overlay)
                nixos-apple-silicon.overlays.default
                nur.overlay
                vim-plugins.overlay
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
              nur.nixosModules.nur
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
                nixpkgs.overlays = [ nur.overlay vim-plugins.overlay ]
                  ++ overlays;
              }
            ];
          };
        };
    };
}
