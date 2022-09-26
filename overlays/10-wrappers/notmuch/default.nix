{ stdenv, makeWrapper, writeTextFile, notmuch }:
let
  config = import ./config.nix {};
  configFile = writeTextFile {
    name = "config";
    text = config;
  };
in
stdenv.mkDerivation {
  name = "notmuch-wrapper";
  version = notmuch.version;
  buildInputs = [ makeWrapper ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir -p $out/bin
    mkdir -p $out/include
    mkdir -p $out/lib
    mkdir -p $out/share
    makeWrapper ${notmuch}/bin/notmuch $out/bin/notmuch --add-flags "--config ${configFile}"
    makeWrapper ${notmuch}/bin/notmuch-emacs-mua $out/bin/notmuch-emacs-mua --add-flags "--config ${configFile}"
    cp -R ${notmuch}/include $out/
    cp -R ${notmuch}/lib $out/
    cp -R ${notmuch}/share $out/
  '';
}
