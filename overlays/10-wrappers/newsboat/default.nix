{
  stdenv,
  makeWrapper,
  writeTextFile,
  newsboat,
}:
let
  config = import ./config.nix { };
  configFile = writeTextFile {
    name = "config";
    text = config;
  };
in
stdenv.mkDerivation {
  name = "grobi-wrapper";
  buildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ newsboat ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${newsboat}/bin/newsboat $out/bin/newsboat --add-flags "-C ${configFile}"
  '';
}
