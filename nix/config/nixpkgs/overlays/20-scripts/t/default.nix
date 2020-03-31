{ pkgs }:

with pkgs;
let
  name = "t";
  source = import ./script.nix {};
in
stdenv.mkDerivation {
  name = name;
  script = writeScript name source;
  phases = [ "installPhase" ];
  propagatedBuildInputs = [ tmux ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/$name
    chmod +x $out/bin/$name
  '';
}
