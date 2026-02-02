self: super:
let
  emacsWithPackages = (super.emacsPackagesNgGen super.emacsGit).emacsWithPackages;
  epkgs = super.epkgs.melpaStablePackages;

  nativeStdenv = super.impureUseNativeOptimizations super.stdenv;
  llvmNativeStdenv = super.impureUseNativeOptimizations super.llvmPackages_latest.stdenv;

  withFlags =
    pkg: flags:
    pkg.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = old.NIX_CFLAGS_COMPILE or "" + super.lib.concatMapStrings (x: " " + x) flags;
    });

  withStdenv = newStdenv: pkg: pkg.override { stdenv = newStdenv; };

  withStdenvAndFlags = newStdenv: pkg: withFlags (withStdenv newStdenv pkg);

  withNativeAndFlags = withStdenvAndFlags nativeStdenv;
  withLLVMNative = withStdenv llvmNativeStdenv;
  withLLVMNativeAndFlags = withStdenvAndFlags llvmNativeStdenv;

  withRustNative =
    pkg:
    pkg.overrideAttrs (old: {
      RUSTFLAGS =
        old.RUSTFLAGS or "" + " -Ctarget-cpu=native -Copt-level=3 -Cdebuginfo=0 -Ccodegen-units=1";
    });

  withRustNativeAndPatches =
    pkg: patches:
    withRustNative (
      pkg.overrideAttrs (old: {
        patches = old.patches or [ ] ++ patches;
      })
    );
in
{
  arc-theme = super.arc-theme.overrideAttrs (oldAttrs: {
    configureFlags = oldAttrs.configureFlags or [ ] ++ [
      "--disable-light"
      "--disable-cinnamon"
      "--disable-gnome-shell"
      "--disable-metacity"
      "--disable-unity"
      "--disable-xfwm"
      "--disable-plank"
      "--disable-openbox"
    ];
  });

  pragmatapro = super.callPackage ./pragmatapro/default.nix { };

  scream-receivers = super.callPackage ./scream-receivers {
    inherit (super)
      stdenv
      lib
      fetchFromGitHub
      alsaLib
      ;
  };

  parsecgaming = super.callPackage ./parsecgaming/default.nix { };

  dotemacs = super.callPackage ./dotemacs {
    inherit (super)
      emacsWithPackages
      epkgs
      symlinkJoin
      makeWrapper
      ;
  };

  beads = super.callPackage ./beads { };
  pulumi = super.callPackage ./pulumi { };
  opencode = super.callPackage ./opencode { };
  rift = super.callPackage ./rift { };
  meshcommander = super.callPackage ./meshcommander { };

  jeveassets = super.callPackage ./jeveassets/default.nix {
    inherit (super)
      stdenv
      fetchzip
      unzip
      jre8
      makeDesktopItem
      ;
  };

  ultra-llama-cpp = super.callPackage ./ultra-llama-cpp { };
}
