{ pkgs }:

with pkgs;
let
  name = "dejli-screenshot";
  source = import ./script.nix {
    inherit pkgs;
  };
in
stdenv.mkDerivation {
  name = name;
  script = writeScript name source;
  phases = [ "installPhase" ];
  propagatedBuildInputs = [ slop shotgun ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/$name
    chmod +x $out/bin/$name
  '';
}
