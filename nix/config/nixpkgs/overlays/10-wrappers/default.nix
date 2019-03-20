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
}
