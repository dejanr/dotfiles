{ stdenv, lib, fetchzip, unzip, jre8, makeDesktopItem, ... }:
let
  mkDesktop = makeDesktopItem {
    name = "Eve Assets";
    exec = "jeveassets";
    comment = "";
    desktopName = "Eve Assets";
    categories = [ "System" ];
  };
in
stdenv.mkDerivation rec {
  pname = "jeveassets";
  version = "7.8.1";
  src = fetchzip {
    url = "http://eve.nikr.net/jeveassets/jeveassets-${version}.zip";
    sha256 = "sha256-RQdmMouXHMGIwfKQ09P5cu9UIsWzX1EcInS+EYYwnV4=";
  };

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    mkdir -pv $out/bin $out/data $out/share

    cp -rf $src/* $out

    cat <<EOT >> $out/bin/jeveassets
    ${jre8}/bin/java -jar $out/jeveassets.jar -noupdate
    EOT

    chmod +x $out/bin/jeveassets
    ln -s ${mkDesktop}/share/applications $out/share/applications
  '';

  meta = with lib; {
    platforms = [ "x86_64-linux" "i686-linux" "aarch64-linux" ];
  };
}
