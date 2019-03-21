{ stdenv, makeWrapper, writeTextFile, dunst, browser, colors, fonts }:
let
  config = import ./config.nix {
    inherit colors fonts browser;
  };
  config-file = writeTextFile {
    name = "dunst-xresources";
    text = config;
  };
in
stdenv.mkDerivation {
  name = "dunstWrapper";
  buildInputs = [ makeWrapper ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper "${dunst}/bin/dunst" $out/bin/dunst --add-flags "-config ${config-file}"
  '';
}
