{ pkgs }:

let
  wallpaper =  pkgs.fetchurl {
    url = "https://w.wallhaven.cc/full/wq/wallhaven-wqery6.jpg";
    sha256 = "0d5416glma4l2sksxszddd6iqchng85j2gf9vc10y14g07cgayg0";
  };
in
  ''
  ${pkgs.feh}/bin/feh --bg-fill ${wallpaper} &
''
