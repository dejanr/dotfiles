{ lib, stdenv, requireFile, unzip }:
let
  version = "1.0";
in
stdenv.mkDerivation rec {
  name = "pragmatapro-${version}";
  src = requireFile rec {
    name = "PragmataPro.zip";
    url = "file://path/to/${name}";
    sha256 = "28c3170ae35e35f23514ba3ef109e8934d5cd1552984b79144cb42bb1527ca32";
    message = ''
      ${name} font not found in nix store, to add it run:

      $ nix-store --add-fixed sha256 ~/downloads/${name}'';
  };
  buildInputs = [ unzip ];
  phases = [ "unpackPhase" "installPhase" ];
  pathsToLink = [ "/share/fonts/truetype/" ];
  sourceRoot = ".";
  installPhase = ''
    install_path=$out/share/fonts/truetype
    mkdir -p $install_path
    find -name "PragmataPro*.ttf" -exec cp {} $install_path \;
  '';
  meta = with lib; {
    homepage = "https://www.fsd.it/shop/fonts/pragmatapro/";
    description = ''
      PragmataPro™ is a condensed monospaced font optimized for screen,
      designed by Fabrizio Schiavi to be the ideal font for coding, math and engineering
    '';
    platforms = platforms.all;
  };
}
