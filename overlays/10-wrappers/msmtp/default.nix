{ stdenv, makeWrapper, writeTextFile, msmtp }:
let
  config = import ./config.nix { };
  configFile = writeTextFile {
    name = "config";
    text = config;
  };
in
stdenv.mkDerivation {
  name = "msmtp-wrapper";
  buildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ msmtp ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${msmtp}/bin/msmtp $out/bin/msmtp --add-flags "-C ${configFile}"
  '';
}
