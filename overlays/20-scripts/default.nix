self: super:

{
  t = import ./t {
    inherit (super) ;
    pkgs = super;
  };

  scratchpad = import ./scratchpad {
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

  cht-sh = import ./cht-sh {
    inherit (super) ;
    pkgs = super;
  };

  wm-workspace = import ./wm-workspace {
    inherit (super) ;
    pkgs = super;
  };
}
