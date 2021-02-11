let
  sources = import ./sources.nix;
in
rec {
  inherit (sources) home-manager nixpkgs NUR;
}
