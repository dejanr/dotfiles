{ stdenv, makeWrapper, writeTextFile, fonts, colors, neomutt }:

let
  config = import ./config.nix {
    inherit colors fonts;
  };
  configFile = writeTextFile {
    name = "config";
    text = config;
  };
in stdenv.mkDerivation {
  name = "neomutt-wrapper";
  buildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ neomutt ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${neomutt}/bin/neomutt $out/bin/neomutt --add-flags "-F ${configFile}"
  '';
}
