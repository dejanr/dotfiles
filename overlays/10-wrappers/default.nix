self: super:

{
  termite = import ./termite {
    inherit (self) colors fonts;
    inherit (super)
      stdenv
      makeWrapper
      writeTextFile
      termite
      ;
  };

  dunst = import ./dunst {
    inherit (self) colors fonts;
    inherit (super)
      stdenv
      makeWrapper
      writeTextFile
      dunst
      ;
    browser = "google-chrome-stable";
  };

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

  i3-config = import ./i3-config {
    inherit (super)
      stdenv
      makeWrapper
      writeTextFile
      ;
  };

  i3blocks = import ./i3blocks {
    inherit (self) colors;
    inherit (super)
      stdenv
      makeWrapper
      writeTextFile
      writeScript
      i3blocks
      xorg
      libnotify
      maim
      xclip
      ;
  };

  newsboat = import ./newsboat {
    inherit (super)
      stdenv
      makeWrapper
      writeTextFile
      newsboat
      ;
  };
}
