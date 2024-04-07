# Shell for bootstrapping flake-enabled nix and other tooling
{ pkgs ? # If pkgs is not defined, instanciate nixpkgs from locked commit
  let
    lock =
      (builtins.fromJSON (builtins.readFile ./flake.lock)).nodes.nixpkgs.locked;
    nixpkgs = fetchTarball {
      url = "https://github.com/nixos/nixpkgs/archive/${lock.rev}.tar.gz";
      sha256 = lock.narHash;
    };
  in
  import nixpkgs { overlays = [ ]; }
, ...
}: {
  default = pkgs.mkShell {
    NIX_CONFIG =
      "extra-experimental-features = nix-command flakes repl-flake";
    nativeBuildInputs = with pkgs; [
      nix # Powerful package manager that makes package management reliable and reproducible
      home-manager # A Nix-based user environment configurator
      sops # Simple and flexible tool for managing secrets
      gnupg # Modern release of the GNU Privacy Guard, a GPL OpenPGP implementation
      age # Modern encryption tool with small explicit keys
    ];
  };
}
