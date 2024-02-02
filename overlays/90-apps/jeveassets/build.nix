let pkgs = import <nixpkgs> { };

in {
  jeveassets = pkgs.callPackage ./default.nix {
    inherit (pkgs) stend lib fetchzip unzip jre8 makeDesktopItem;
  };
}

