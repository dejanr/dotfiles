{
  stdenv,
  makeWrapper,
  writeTextFile,
  kitty,
  useDejliBrowser ? false,
}:
let
  config = import ./config.nix { inherit kitty useDejliBrowser; };
  configFile = writeTextFile {
    name = "i3-config";
    text = config;
  };
in
stdenv.mkDerivation {
  name = "i3-config";
  buildInputs = [ makeWrapper ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir $out
    ln -s ${configFile} $out/config
  '';
}
