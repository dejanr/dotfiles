self: super:

{
  mfc9332cdwlpr = import ./mfc9332cdwlpr {
    inherit (super)
      lib
      coreutils
      dpkg
      fetchurl
      file
      ghostscript
      gnugrep
      gnused
      makeWrapper
      perl
      pkgs
      stdenv
      which
      ;
  };
}
