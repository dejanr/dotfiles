{
  stdenv,
  makeWrapper,
  writeTextFile,
  i3-gaps,
}:
let
  config = import ./config.nix { };
  configFile = writeTextFile {
    name = "i3-config";
    text = config;
  };
in
stdenv.mkDerivation {
  name = "i3-config";
  buildInputs = [ makeWrapper ];
  propagatedBuildInputs = [ i3-gaps ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir $out
    ln -s ${configFile} $out/config
  '';
}
