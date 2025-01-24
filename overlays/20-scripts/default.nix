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

  entropia = import ./entropia {
    inherit (super);
    pkgs = super;
  };

  dejli-gif = import ./dejli-gif {
    inherit (super);
    pkgs = super;
  };

  dejli-screenshot = import ./dejli-screenshot {
    inherit (super);
    pkgs = super;
  };

  fish-throw = import ./fish-throw {
    inherit (super);
    pkgs = super;
  };

  wine-prefix = import ./wine-prefix {
    inherit (super);
    pkgs = super;
  };

  cht-sh = import ./cht-sh {
    inherit (super);
    pkgs = super;
  };
}
