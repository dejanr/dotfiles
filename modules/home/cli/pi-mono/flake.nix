{
  description = "Pi-mono extensions workspace";

  inputs = {
    devenv-root = {
      url = "file+file:///dev/null";
      flake = false;
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";
    devenv.inputs.flake-parts.follows = "flake-parts";
    pi-mono = {
      url = "github:badlogic/pi-mono";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      flake-parts,
      ...
    }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];

      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          formatter = pkgs.nixfmt-tree;

          packages.pi-mono = import ./nix/package.nix {
            inherit pkgs;
            pi-mono-src = inputs.pi-mono;
          };
          packages.pi-mono-extensions = import ./nix/extensions.nix {
            inherit pkgs;
            extensions-src = self;
            pi-mono-src = inputs.pi-mono;
          };
          packages.extensions = config.packages.pi-mono-extensions;
          packages.default = config.packages.pi-mono-extensions;

          devenv.shells.default = {
            name = "pi-mono";

            imports = [ ./devenv.nix ];
          };
        };
    };
}
