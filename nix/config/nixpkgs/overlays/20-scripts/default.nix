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

  mutt-openfile = import ./mutt-openfile {
    inherit (super);
    pkgs = super;
  };

  mutt-openimage = import ./mutt-openimage {
    inherit (super);
    pkgs = super;
  };

  mutt-sync = import ./mutt-sync {
    inherit (super);
    pkgs = super;
  };

  eu = import ./eu {
    inherit (super);
    pkgs = super;
  };
}
