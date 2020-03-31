self: super:
let
  multiNativeStdenv = super.impureUseNativeOptimizations super.multiStdenv;
  emacsWithPackages = (super.emacsPackagesNgGen super.emacsGit).emacsWithPackages;
  epkgs = super.epkgs.melpaStablePackages;
in
{
  pragmatapro = super.callPackage ./pragmatapro/default.nix {};

  dxvk = super.callPackage ./dxvk {
    multiStdenv = multiNativeStdenv;
  };

  d9vk = super.callPackage ./d9vk {
    multiStdenv = multiNativeStdenv;
  };

  parsecgaming = super.callPackage ./parsecgaming/default.nix {};

  dotemacs = super.callPackage ./dotemacs {
    inherit (super) emacsWithPackages epkgs symlinkJoin makeWrapper;
  };
}
