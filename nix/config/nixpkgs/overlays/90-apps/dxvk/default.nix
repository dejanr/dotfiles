 { lib, stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "dxvk";
  version = "1.7";

  src = fetchurl {
    url = "https://github.com/doitsujin/dxvk/releases/download/v${version}/dxvk-${version}.tar.gz";
    sha256 = "18f7lj6b08abywidsq3s98kiwwn1jbbjzg7clm8bs93cj0wq5mv7";
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
