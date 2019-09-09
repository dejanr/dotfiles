{ pkgs }:

with pkgs;

let
  name = "wm-lock";
  source = import ./script.nix { i3lock-pixeled = pkgs.i3lock-pixeled; };
in stdenv.mkDerivation {
  name = name;
  script = writeScript name source;
  phases = [ "installPhase" ];
  propagatedBuildInputs = [ pkgs.i3lock-pixeled ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/$name
    chmod +x $out/bin/$name
  '';
}
