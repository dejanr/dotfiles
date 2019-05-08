self: super:

{
  alacritty = import ./alacritty {
    inherit (self) colors fonts;
    inherit (super) stdenv makeWrapper writeTextFile alacritty;
  };

  termite = import ./termite {
    inherit (self) colors fonts;
    inherit (super) stdenv makeWrapper writeTextFile termite;
  };

  grobi = import ./grobi {
    inherit (super) stdenv makeWrapper writeTextFile grobi;
  };

  dunst = import ./dunst {
    inherit (self) colors fonts;
    inherit (super) stdenv makeWrapper writeTextFile dunst;
    browser = "firefox";
  };

  mfc9332cdwlpr = import ./mfc9332cdwlpr {
    inherit (super) coreutils dpkg fetchurl file ghostscript gnugrep gnused
makeWrapper perl pkgs stdenv which;
  };
}
