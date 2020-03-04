self: super: let
  multiNativeStdenv = super.impureUseNativeOptimizations super.multiStdenv;
  emacsWithPackages = (super.emacsPackagesNgGen super.emacsGit).emacsWithPackages;
  epkgs = super.epkgs.melpaStablePackages;
in {
  pragmatapro = super.callPackage ./pragmatapro/default.nix { };

  st = super.callPackage ./st/default.nix {
    inherit (self) colors fonts;
    inherit (super) writeTextFile st;
  };

  wine = super.callPackage ./wine/default.nix {
    inherit (super) wine fetchurl fetchFromGitHub git perl utillinux autoconf libtxc_dxtn_s2tc;
  };

  dxvk = super.callPackage ./dxvk {
    multiStdenv = multiNativeStdenv;
  };

  d9vk = super.callPackage ./d9vk {
    multiStdenv = multiNativeStdenv;
  };

  parsecgaming = super.callPackage ./parsecgaming/default.nix { };

  dotemacs = super.callPackage ./dotemacs {
    inherit (super) emacsWithPackages epkgs symlinkJoin makeWrapper;
  };
}
