{ pkgs }:

with pkgs;
let
  name = "music";
  eu = import ./script.nix {
    wine = pkgs.wine;
    prefix = "~/.entropia";
  };
  eufs = import ./script.nix {
    wine = pkgs.wine;
    prefix = "~/.entropia-fs";
  };
in
stdenv.mkDerivation {
  name = name;
  euScript = writeScript name eu;
  eufsScript = writeScript name eu;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$euScript" > $out/bin/entropia
    echo "$eufsScript" > $out/bin/entropia-fs
    chmod +x $out/bin/entropia
    chmod +x $out/bin/entropia
  '';
}
