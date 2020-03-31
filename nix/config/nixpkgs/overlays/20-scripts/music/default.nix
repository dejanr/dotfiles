{ pkgs }:

with pkgs;

let
  name = "music";
  source = import ./script.nix {
    mpsyt = "${mps-youtube}/bin/mpsyt";
    tmux = "${tmux}/bin/tmux";
  };
in stdenv.mkDerivation {
  name = name;
  script = writeScript name source;
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/$name
    chmod +x $out/bin/$name
  '';
}
