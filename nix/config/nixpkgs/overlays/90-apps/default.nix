self: super: let
  multiNativeStdenv = super.impureUseNativeOptimizations super.multiStdenv;
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
}
