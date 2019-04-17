self: super:

{
  t = import ./t {
    inherit (super);
    pkgs = super;
  };

  wm-lock = import ./wm-lock {
    inherit (super);
    pkgs = super;
  };

  wm-wallpaper = import ./wm-wallpaper {
    inherit (super);
    pkgs = super;
  };

  music = import ./music {
    inherit (super);
    pkgs = super;
  };
}
