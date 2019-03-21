self: super:

{
  t = import ./t {
    inherit (super) stdenv writeScript tmux;
  };

  wm-lock = import ./wm-lock {
    inherit (super) stdenv writeScript i3lock-fancy;
  };
}
