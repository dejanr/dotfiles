self: super:
let
  emacsWithPackages = (super.emacsPackagesNgGen super.emacsGit).emacsWithPackages;
  epkgs = super.epkgs.melpaStablePackages;
in
{
  pragmatapro = super.callPackage ./pragmatapro/default.nix {};

  dxvk = super.callPackage ./dxvk {};

  parsecgaming = super.callPackage ./parsecgaming/default.nix {};

  dotemacs = super.callPackage ./dotemacs {
    inherit (super) emacsWithPackages epkgs symlinkJoin makeWrapper;
  };
}
