{ pkgs }:

with pkgs;
let
  name = "screenshot";
  source = import ./script.nix {
    inherit pkgs;
  };
in
stdenv.mkDerivation {
  name = name;
  script = writeScript name source;
  phases = [ "installPhase" ];
  propagatedBuildInputs = [ hacksaw shotgun ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/$name
    chmod +x $out/bin/$name
  '';
}