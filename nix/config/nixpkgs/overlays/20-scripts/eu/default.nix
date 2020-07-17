{ pkgs }:

with pkgs;
let
  name = "music";
  eu = import ./script.nix {
    wine = pkgs.wine;
    prefix = "~/.wine";
  };
  eufs = import ./script.nix {
    wine = pkgs.wine;
    prefix = "~/.wine-fs";
  };
in
stdenv.mkDerivation {
  name = name;
  euScript = writeScript name eu;
  eufsScript = writeScript name eu;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$euScript" > $out/bin/eu
    echo "$eufsScript" > $out/bin/eufs
    chmod +x $out/bin/eu
    chmod +x $out/bin/eufs
  '';
}
