{ pkgs }:

with pkgs;
let
  name = "entropia";
  eu = import ./script.nix {
    wine = pkgs.wine;
    prefix = ".entropia";
  };
  eufs = import ./script.nix {
    wine = pkgs.wine;
    prefix = ".entropia-fs";
  };
  euxs = import ./script.nix {
    wine = pkgs.wine;
    prefix = ".entropia-xs";
  };
in
stdenv.mkDerivation {
  name = name;
  euScript = writeScript name eu;
  eufsScript = writeScript name eufs;
  euxsScript = writeScript name euxs;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$euScript" > $out/bin/entropia
    echo "$eufsScript" > $out/bin/entropia-fs
    echo "$euxsScript" > $out/bin/entropia-xs
    chmod +x $out/bin/entropia
    chmod +x $out/bin/entropia-fs
  '';
}
