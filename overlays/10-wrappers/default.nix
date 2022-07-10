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

  neomutt = import ./neomutt {
    inherit (self) colors fonts msmtp isync notmuch;
    inherit (super) stdenv makeWrapper writeTextFile neomutt;
  };

  msmtp = import ./msmtp {
    inherit (super) stdenv makeWrapper writeTextFile msmtp;
  };

  isync = import ./isync {
    inherit (super) stdenv makeWrapper writeTextFile isync;
  };

  notmuch = import ./notmuch {
    inherit (super) stdenv makeWrapper writeTextFile notmuch;
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
    inherit (super) lib coreutils dpkg fetchurl file ghostscript gnugrep gnused
      makeWrapper perl pkgs stdenv which
      ;
  };

  i3-config = import ./i3-config {
    inherit (self) colors fonts;
    inherit (super) stdenv makeWrapper writeTextFile i3-gaps;
  };

  i3blocks = import ./i3blocks {
    inherit (self) colors;
    inherit (super) stdenv makeWrapper writeTextFile writeScript i3blocks xorg libnotify maim xclip;
  };

  newsboat = import ./newsboat {
    inherit (super) stdenv makeWrapper writeTextFile newsboat;
  };
}
