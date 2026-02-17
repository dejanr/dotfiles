{ pkgs }:

with pkgs;
let
  name = "comfy-model";
  source = import ./script.nix { inherit pkgs; };
in
stdenv.mkDerivation {
  name = name;
  script = writeScript name source;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    ln -s "$script" $out/bin/$name
  '';
}
