self: super: {
  pragmatapro = super.callPackage ./pragmatapro/default.nix { };
  st = super.callPackage ./st/default.nix {
    inherit (self) colors fonts;
    inherit (super) writeTextFile st;
  };
}
