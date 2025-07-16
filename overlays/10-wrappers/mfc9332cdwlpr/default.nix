{
  lib,
  coreutils,
  dpkg,
  fetchurl,
  file,
  ghostscript,
  gnugrep,
  gnused,
  makeWrapper,
  perl,
  pkgs,
  stdenv,
  which,
}:

stdenv.mkDerivation rec {
  name = "mfc9332cdwlpr-${version}";
  version = "1.1.3-0";

  src = fetchurl {
    url = "https://download.brother.com/welcome/dlf101620/${name}.i386.deb";
    sha256 = "0mmqcwpbw4dx2hqaxhnvm52jm84vq8c55xrixsvapxwrdbpkdcca";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
  ];

  phases = [ "installPhase" ];

  installPhase = ''
    dpkg-deb -x $src $out
    dir=$out/opt/brother/Printers/mfc9332cdw
    filter=$dir/lpd/filtermfc9332cdw
    substituteInPlace $filter \
      --replace /usr/bin/perl ${perl}/bin/perl \
      --replace "BR_PRT_PATH =~" "BR_PRT_PATH = \"$dir/\"; #" \
      --replace "PRINTER =~" "PRINTER = \"mfc9332cdw\"; #"
    wrapProgram $filter \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          file
          ghostscript
          gnugrep
          gnused
          which
        ]
      }
    # need to use i686 glibc here, these are 32bit proprietary binaries
    interpreter=${pkgs.pkgsi686Linux.glibc}/lib/ld-linux.so.2
    patchelf --set-interpreter "$interpreter" $dir/lpd/brmfc9332cdwfilter
  '';

  meta = {
    description = "Brother MFC-9332CDW LPR printer driver";
    homepage = "http://www.brother.com/";
    license = lib.licenses.unfree;
    maintainers = [ lib.maintainers.fuzzy-id ];
    platforms = [ "i686-linux" ];
  };
}
