{
  description = "dotfiles";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    home-manager.url =  "github:nix-community/home-manager/master";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ...}:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;

      config = {
        allowUnfree = true;
        allowBroken = true;
        allowUnsupportedSystem = true;
        android_sdk.accept_license = true;
      };
    };

    lib = nixpkgs.lib;
  in {
    homeManagerConfigurations = {
      dejanr = home-manager.lib.homeManagerConfiguration {
        inherit system pkgs;

        username = "dejanr";
        homeDirectory = "/home/dejanr";
        configuration = {
          imports = [
            ./users/dejanr/home.nix
          ];
        };
      };
    };

    nixosConfigurations = {
      omega = lib.nixosSystem {
        inherit system;

        modules = [
          ./hosts/omega/configuration.nix
        ];
      };
    };
  };
}
