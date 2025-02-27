{ pkgs }:
with pkgs;
let
  versionNumber = "4.23.0";
in
stdenv.mkDerivation {
  pname = "rift";

  version = versionNumber;

  src = fetchurl {
    url = "https://riftforeve.online/download/debian/rift_${versionNumber}_amd64.deb";
    sha256 = "sha256-sZMhkTNfiScf1NoIf5Qqzzl07lV6lW90dY2xznhWb3M=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    makeWrapper
  ];

  buildInputs = [
    alsa-lib
    xorg.libX11
    glib
    freetype
    libxkbcommon
    xorg.libICE
    xorg.libXrender
    xorg.libSM
    fontconfig
    pango
    gtk3
    pulseaudio
    qt5.qtbase
    qt5.qtx11extras
    libsecret
    libdrm
    mesa
    nss
    nspr
    xorg.libXdamage
    xorg.libxshmfence
    xorg.libXtst
    libGL
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
    license = licenses.unfree;
    maintainers = with maintainers; [ jcouyang ];
    platforms = [ "x86_64-linux" ];
  };
}
