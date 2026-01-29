{ pkgs }:

with pkgs;
let
  name = "wm-lock";
  source = import ./script.nix { i3lock-color = pkgs.i3lock-color; };
in
stdenv.mkDerivation {
  name = name;
  script = writeScript name source;
  phases = [ "installPhase" ];
  propagatedBuildInputs = [ pkgs.i3lock-color ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/$name
    chmod +x $out/bin/$name
  '';
}
