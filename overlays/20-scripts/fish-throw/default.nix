{ pkgs }:

with pkgs;
let
  name = "fish-throw";
  macro = import ./macro.nix { };
  macroFile = writeTextFile {
    name = "fish-throw-macro";
    text = macro;
  };
  source = import ./script.nix {
    inherit pkgs macroFile;
  };
in
stdenv.mkDerivation {
  name = name;
  script = writeScript name source;
  phases = [ "installPhase" ];
  propagatedBuildInputs = [ ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/$name
    chmod +x $out/bin/$name
  '';
}
