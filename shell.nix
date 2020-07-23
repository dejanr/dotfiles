let
  sources = import ./nix/sources.nix;
  nixpkgs = sources.nixpkgs;
  pkgs = import nixpkgs {};
  dotfiles = import ./packages/dotfiles.nix {};
in
pkgs.mkShell {
  src = ./packages/default.nix;

  name = "dotfiles-shell";

  buildInputs = [
    dotfiles
    pkgs.morph
    pkgs.nixpkgs-fmt
    (import sources.home-manager {inherit pkgs;}).home-manager
  ];

  shellHook = ''
    export PATH="./result/bin:$PATH"
    export NIX_PATH="nixos-config=/etc/nixos/configuration.nix:nixpkgs=${nixpkgs}:home-manager=${sources."home-manager"}"
  '';
}
