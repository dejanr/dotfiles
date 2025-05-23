{
  description = "NixOS configuration";

  inputs = {
    ssh-keys = {
      url = "https://github.com/dejanr.keys";
      flake = false;
    };

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix.url = "github:nixos/nix/2.27.1";

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

    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self
    , home-manager
    , nix-darwin
    , nixos-apple-silicon
    , nixpkgs
    , nix
    , nur
    , nix-gaming
    , rust-overlay
    , stylix
    , sops-nix
    , disko
    , devenv
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
      mkSystem = pkgs: system: hostConfig: hostName:
        pkgs.lib.nixosSystem
          {
            system = system;
            modules = [
              {
                networking.hostName = hostName;
                networking.timeServers = [ "1.amazon.pool.ntp.org" "2.amazon.pool.ntp.org" "3.amazon.pool.ntp.org" ];
              }
              stylix.nixosModules.stylix
              nur.modules.nixos.default
              nix-gaming.nixosModules.pipewireLowLatency
              sops-nix.nixosModules.sops
              disko.nixosModules.disko
              ./modules/system/configuration.nix
              (./. + "/hosts/${hostConfig}/configuration.nix")
              home-manager.nixosModules.home-manager
              {
                home-manager = {
                  useUserPackages = true;
                  useGlobalPkgs = true;
                  extraSpecialArgs = { inherit inputs system; };
                  users.dejanr.imports =
                    [ (./. + "/hosts/${hostConfig}/home.nix") ];
                  sharedModules = [
                    sops-nix.homeManagerModules.sops
                  ];
                };
                nixpkgs.overlays = [
                  nix-gaming.overlays.default
                  (import rust-overlay)
                  nixos-apple-silicon.overlays.apple-silicon-overlay
                  nixos-apple-silicon.overlays.default
                  nur.overlays.default
                  devenv.overlays.default
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
        alpha = mkSystem inputs.nixpkgs "x86_64-linux" "alpha" "alpha";
        atlas = mkSystem inputs.nixpkgs "x86_64-linux" "atlas" "atlas";
        omega = mkSystem inputs.nixpkgs "x86_64-linux" "omega" "omega";
        m910q1 = mkSystem inputs.nixpkgs "x86_64-linux" "m910q" "m910q1";
        m910q2 = mkSystem inputs.nixpkgs "x86_64-linux" "m910q" "m910q2";
        m910q3 = mkSystem inputs.nixpkgs "x86_64-linux" "m910q" "m910q3";
        m910q4 = mkSystem inputs.nixpkgs "x86_64-linux" "m910q" "m910q4";
        theory = mkSystem inputs.nixpkgs "aarch64-linux" "theory" "theory";
        vm = mkSystem inputs.nixpkgs "x86_64-linux" "vm" "vm";
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
                  sharedModules = [
                    sops-nix.homeManagerModules.sops
                  ];
                };
                nixpkgs.overlays = [ nur.overlays.default ] ++ overlays;
              }
            ];
          };
        };
    };
}
