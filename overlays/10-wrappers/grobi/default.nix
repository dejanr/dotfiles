{ stdenv, makeWrapper, writeTextFile, grobi }:
let
  config = import ./config.nix {};
  configFile = writeTextFile {
    name = "config";
    text = config;
  };
in
stdenv.mkDerivation {
  name = "grobi-wrapper";
  buildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ grobi ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${grobi}/bin/grobi $out/bin/grobi --add-flags "-C ${configFile}"
  '';
}
