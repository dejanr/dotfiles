self: super:
let
  emacsWithPackages = (super.emacsPackagesNgGen super.emacsGit).emacsWithPackages;
  epkgs = super.epkgs.melpaStablePackages;

  nativeStdenv = super.impureUseNativeOptimizations super.stdenv;

  withFlags = pkg: flags:
    pkg.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = old.NIX_CFLAGS_COMPILE or "" +
      super.lib.concatMapStrings (x: " " + x) flags;
    });

  withStdenv = newStdenv: pkg:
    pkg.override { stdenv = newStdenv; };

  withStdenvAndFlags = newStdenv: pkg:
    withFlags (withStdenv newStdenv pkg);

  withNativeAndFlags = withStdenvAndFlags nativeStdenv;
in
{
  pragmatapro = super.callPackage ./pragmatapro/default.nix {};

  dxvk = super.callPackage ./dxvk {};

  scream-receivers = super.callPackage ./scream-receivers {
    inherit (super) stdenv lib fetchFromGitHub alsaLib;
  };

  pyfa = super.callPackage ./pyfa {
    inherit (super) python3 fetchurl makeDesktopItem writeScriptBin;
  };

  parsecgaming = super.callPackage ./parsecgaming/default.nix {};

  dotemacs = super.callPackage ./dotemacs {
    inherit (super) emacsWithPackages epkgs symlinkJoin makeWrapper;
  };
}
