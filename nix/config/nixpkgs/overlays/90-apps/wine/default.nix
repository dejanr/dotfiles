{ wine, fetchurl, fetchFromGitHub, git, perl, utillinux, autoconf, libtxc_dxtn_s2tc }:

(
  (
    wine.override {
      # Note: we cannot set wineRelease to staging here, as it will no longer allow us
      # to use overrideAttrs
      wineBuild = "wineWow";

      gstreamerSupport = false;
      netapiSupport = false;
      cupsSupport = false;
      gphoto2Support = false;
      saneSupport = false;
      openclSupport = false;
      ldapSupport = false;
      gsmSupport = false;
    }
  ).overrideAttrs (
    oldAttrs: rec {
      version = "4.19";

      src = fetchurl {
        url = "https://dl.winehq.org/wine/source/4.x/wine-${version}.tar.xz";
        sha256 = "086fd6h8qzd9rjxvxxw9hsyaglpvlybdrg5jzp55miknnvmvw6in";
      };

      staging = fetchFromGitHub {
        owner = "wine-staging";
        repo = "wine-staging";
        rev = "v${version}";
        sha256 = "0dln4pdvwfy0lclzvdy9pw93ankn946nxz8a0j2ldwrppl5gap4r";
      };

      NIX_CFLAGS_COMPILE = "-O3 -march=native -fomit-frame-pointer";
    }
  )
).overrideDerivation (
  drv: {
    name = "wine-wow-${drv.version}-staging";

    buildInputs = drv.buildInputs ++ [ git perl utillinux autoconf libtxc_dxtn_s2tc ];

    postPatch =
      ''
        # staging patches
        patchShebangs tools
        cp -r ${drv.staging}/patches .
        chmod +w patches
        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all
        cd ..
      '';
  }
)
