{ stdenv, makeWrapper, writeTextFile, writeScript, colors, i3blocks }:

let
  config = import ./config.nix {
    inherit writeScript colors;
  };
  execPath = "bin";
  configFile = writeTextFile {
    name = "config";
    text = config;
  };
in stdenv.mkDerivation {
  name = "i3blocks-wrapper";
  buildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ i3blocks ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${i3blocks}/${execPath}/i3blocks $out/bin/i3blocks --add-flags "-c ${configFile}"
  '';
}
