{
  pkgs ? import <nixpkgs> { },
}:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "sway-scratchpad";
  version = "0.2.1";
  src = pkgs.fetchFromGitHub {
    owner = "matejc";
    repo = pname;
    rev = "refs/tags/v${version}";
    sha256 = "sha256-Ic0vzxby2vJTqdmfDDAYs0TNyntMJuEknbXK3wRjnR4=";
  };
  cargoHash = "sha256-Ueb/KHdIil7cHjTqZw5HqWrQ5uhzzs3k1nuF5TguJ5o=";
}
