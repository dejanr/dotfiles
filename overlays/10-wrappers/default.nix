self: super:

{
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

  i3-config = self.callPackage ./i3-config { };

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
      systemd
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
