{ stdenv, makeWrapper, writeTextFile, isync }:
let
  config = import ./config.nix { };
  configFile = writeTextFile {
    name = "config";
    text = config;
  };
in
stdenv.mkDerivation {
  name = "isync-wrapper";
  buildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ isync ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${isync}/bin/mbsync $out/bin/mbsync --add-flags "-c ${configFile}"
  '';
}
