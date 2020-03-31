self: super:
let
  theme = "dark";
in
{
  colors = {} // (import ./colors.nix { inherit theme; });
  fonts = {} // import ./fonts.nix;
}
