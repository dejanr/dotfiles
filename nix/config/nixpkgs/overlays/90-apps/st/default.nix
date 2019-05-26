{ colors, fonts, st, fetchurl, writeTextFile }:

let
  clipboard = fetchurl {
    url = "https://st.suckless.org/patches/clipboard/st-clipboard-0.8.2.diff";
    sha1 = "kcnjw41pn5613q0ny0ah28ga6dqivl5j";
  };
  config = import ./config.nix { inherit colors fonts; };
  configFile = writeTextFile {
    name = "config.h";
    text = config;
  };
in st.override {
  patches = [
    clipboard
  ];
  conf = builtins.readFile configFile;
}
