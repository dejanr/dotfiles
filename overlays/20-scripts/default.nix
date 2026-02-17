self: super:

{
  t = import ./t {
    inherit (super) ;
    pkgs = super;
  };

  comfy-model = import ./comfy-model {
    inherit (super) ;
    pkgs = super;
  };

  wm-lock = import ./wm-lock {
    inherit (super) ;
    pkgs = super;
  };

  wm-wallpaper = import ./wm-wallpaper {
    inherit (super) ;
    pkgs = super;
  };

  music = import ./music {
    inherit (super) ;
    pkgs = super;
  };

  dejli-audio = import ./dejli-audio {
    inherit (super) ;
    pkgs = super;
  };

  dejli-gif = import ./dejli-gif {
    inherit (super) ;
    pkgs = super;
  };

  dejli-screenshot = import ./dejli-screenshot {
    inherit (super) ;
    pkgs = super;
  };

  wine-prefix = import ./wine-prefix {
    inherit (super) ;
    pkgs = super;
  };

  cht-sh = import ./cht-sh {
    inherit (super) ;
    pkgs = super;
  };

  wm-workspace = import ./wm-workspace {
    inherit (super) ;
    pkgs = super;
  };
}
