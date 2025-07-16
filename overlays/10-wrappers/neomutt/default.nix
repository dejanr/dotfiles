{
  stdenv,
  makeWrapper,
  writeTextFile,
  fonts,
  colors,
  neomutt,
  msmtp,
  isync,
  notmuch,
}:
let
  mailcap = import ./config/mailcap.nix { };
  mailcapFile = writeTextFile {
    name = "mailcap";
    text = mailcap;
  };
  config = import ./config/mutt.nix {
    inherit
      colors
      fonts
      mailcapFile
      msmtp
      isync
      ;
  };
  configFile = writeTextFile {
    name = "config";
    text = config;
  };
in
stdenv.mkDerivation {
  name = "neomutt-wrapper";
  buildInputs = [
    notmuch
    makeWrapper
  ];
  propagatedBuildInputs = [ neomutt ];
  phases = [ "buildPhase" ];
  buildCommand = ''
    mkdir -p $out/bin
    makeWrapper ${neomutt}/bin/neomutt $out/bin/neomutt --add-flags "-F ${configFile}"
  '';
}
