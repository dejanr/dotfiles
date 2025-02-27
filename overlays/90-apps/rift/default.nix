{ pkgs, lib }:

let
  versionNumber = "4.23.0";
in
pkgs.stdenv.mkDerivation {
  pname = "rift";

  version = versionNumber;

  src = pkgs.fetchurl {
    url = "https://riftforeve.online/download/debian/rift_${versionNumber}_amd64.deb";
    sha256 = "sha256-sZMhkTNfiScf1NoIf5Qqzzl07lV6lW90dY2xznhWb3M=";
  };

  nativeBuildInputs = [
    pkgs.autoPatchelfHook
    pkgs.dpkg
    pkgs.makeWrapper
  ];

  buildInputs = [
    pkgs.alsa-lib
    pkgs.xorg.libX11
    pkgs.glib
    pkgs.freetype
    pkgs.libxkbcommon
    pkgs.xorg.libICE
    pkgs.xorg.libXrender
    pkgs.xorg.libSM
    pkgs.fontconfig
    pkgs.pango
    pkgs.gtk3
    pkgs.pulseaudio
    pkgs.qt5.qtbase
    pkgs.qt5.qtx11extras
    pkgs.libsecret
    pkgs.libdrm
    pkgs.mesa
    pkgs.nss
    pkgs.nspr
    pkgs.xorg.libXdamage
    pkgs.xorg.libxshmfence
    pkgs.xorg.libXtst
    pkgs.libGL
  ];

  unpackPhase = ''
    mkdir -p $out
    dpkg -x $src $out
    ls -la $out/usr/bin/rift
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/applications
    dpkg -x $src $out
    ls -la $out
    wrapProgram $out/usr/lib/nohus/rift/bin/rift \
      --prefix LD_LIBRARY_PATH : $out/usr/rift/lib/nohus/rift/lib
  '';

  dontWrapQtApps = true;

  meta = with lib; {
    description = "Rift";
    homepage = "https://rift";
    license = licenses.free;
    maintainers = with maintainers; [ dejanr ];
    platforms = [ "x86_64-linux" ];
  };
}
