{ stdenv, lib, fetchurl }:

stdenv.mkDerivation rec {
  pname = "dxvk";
  version = "1.10";

  src = fetchurl {
    url = "https://github.com/doitsujin/dxvk/releases/download/v${version}/dxvk-${version}.tar.gz";
    sha256 = "sha256-oVvHwd9mFYogXEmIg7CyFjkNWPShKGV5kK81dDG5znc=";
  };

  phases = "unpackPhase installPhase fixupPhase";

  installPhase = ''
    mkdir -p $out/share/dxvk/

    cp setup_dxvk.sh $out/share/dxvk/setup_dxvk
    chmod +x $out/share/dxvk/setup_dxvk

    mkdir -p $out/bin/
    ln -s $out/share/dxvk/setup_dxvk $out/bin/setup_dxvk

    cp -r x64/ $out/share/dxvk/
    cp -r x32/ $out/share/dxvk/
  '';

  fixupPhase = ''
    patchShebangs $out/share/dxvk/setup_dxvk
  '';

  meta = with lib; {
    platforms = platforms.linux;
    licenses = [ licenses.zlib licenses.png ];
  };
}
