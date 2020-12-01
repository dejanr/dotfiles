{ stdenv, fetchurl, wine, fetchFromGitHub, git, utillinux, autoconf, python3, perl }:

# Latest staging version of Wine
((wine.override {
  # Note: we cannot set wineRelease to staging here, as it will no longer allow us
  # to use overrideAttrs
  wineRelease = "unstable";
  wineBuild = "wineWow";

  cupsSupport = false;
  gphoto2Support = false;
  saneSupport = false;
  openclSupport = false;
  gsmSupport = false;

  gstreamerSupport = false;
}).overrideAttrs (old: rec {
  version = "5.21";
  name = "wine-wow-${version}-staging";

  src = fetchFromGitHub {
    owner = "wine-mirror";
    repo = "wine";
    rev = "wine-${version}";
    sha256 = "g4Tf9nv/W7SPnpa3Mks7GiVyhOo+Xgu1kRrbKYtqTmQ=";
  };

  staging = fetchFromGitHub {
    owner = "wine-staging";
    repo = "wine-staging";
    rev = "v${version}";
    sha256 = "8IIjdGyRZf2v0dVvinqA2gvjR5eCXxN3+tWj1eCjjWA=";
  };

  NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";

  nativeBuildInputs = old.nativeBuildInputs ++ [
    git
    perl
    utillinux
    autoconf
    python3
    perl
  ];

  postPatch = old.postPatch or "" + ''
    patchShebangs tools
    cp -r ${staging}/patches .
    chmod +w patches
    cd patches
    patchShebangs gitapply.sh
    ./patchinstall.sh DESTDIR="$PWD/.." --all
    cd ..
  '';
}))
