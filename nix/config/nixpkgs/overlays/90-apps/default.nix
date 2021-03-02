self: super:
let
  emacsWithPackages = (super.emacsPackagesNgGen super.emacsGit).emacsWithPackages;
  epkgs = super.epkgs.melpaStablePackages;
in
{
  pragmatapro = super.callPackage ./pragmatapro/default.nix {};

  dxvk = super.callPackage ./dxvk {};

  #wine = super.callPackage ./wine {
  #  inherit (super) fetchFromGitHub wine git perl utillinux autoconf python3;
  #};

  pyfa = super.callPackage ./pyfa {
    inherit (super) python3 fetchurl makeDesktopItem writeScriptBin;
  };

  parsecgaming = super.callPackage ./parsecgaming/default.nix {};

  dotemacs = super.callPackage ./dotemacs {
    inherit (super) emacsWithPackages epkgs symlinkJoin makeWrapper;
  };
}
