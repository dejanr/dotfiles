self: super:
let
  emacsWithPackages = (super.emacsPackagesNgGen super.emacsGit).emacsWithPackages;
  epkgs = super.epkgs.melpaStablePackages;

  nativeStdenv = super.impureUseNativeOptimizations super.stdenv;
  llvmNativeStdenv = super.impureUseNativeOptimizations super.llvmPackages_latest.stdenv;

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
  withLLVMNative = withStdenv llvmNativeStdenv;
  withLLVMNativeAndFlags = withStdenvAndFlags llvmNativeStdenv;

  withRustNative = pkg: pkg.overrideAttrs (old: {
    RUSTFLAGS = old.RUSTFLAGS or "" + " -Ctarget-cpu=native -Copt-level=3 -Cdebuginfo=0 -Ccodegen-units=1";
  });

  withRustNativeAndPatches = pkg: patches: withRustNative (pkg.overrideAttrs (old: {
    patches = old.patches or [] ++ patches;
  }));
in
{
  pragmatapro = super.callPackage ./pragmatapro/default.nix {};

  dxvk = super.callPackage ./dxvk {};

  vkd3d = withNativeAndFlags (super.callPackage ./vkd3d-proton {
    wine = self.wine;
  }) [ "-O3" ];

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
