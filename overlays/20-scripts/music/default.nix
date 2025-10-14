{ pkgs }:

let
  name = "music";
  source = import ./script.nix {
    mpv = "${pkgs.pipe-viewer}/bin/mpv";
    pipe-viewer = "${pkgs.pipe-viewer}/bin/pipe-viewer";
    tmux = "${pkgs.tmux}/bin/tmux";
  };
in
pkgs.stdenv.mkDerivation {
  name = name;
  script = pkgs.writeScript name source;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/$name
    chmod +x $out/bin/$name
  '';
}
