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
      pulseaudio
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
