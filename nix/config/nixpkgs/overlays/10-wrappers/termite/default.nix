{ stdenv, makeWrapper, writeTextFile, termite, fonts, colors }:

let
  config = import ./config.nix {
    inherit colors fonts;
  };
  execPath = "bin";
  configFile = writeTextFile {
    name = "config";
    text = config;
  };
in stdenv.mkDerivation {
  name = "termite-wrapper";
  buildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ termite ];
  phases = [ "buildPhase" ];
  pathsToLink = [ "/share" "/nix-support" ];
  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${termite}/${execPath}/termite $out/bin/termite --add-flags "--config ${configFile}"
  '';
  passthru.terminfo = termite.terminfo;
}
