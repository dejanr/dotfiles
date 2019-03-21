{ stdenv, writeScript, i3lock-fancy }:

let
  name = "wm-lock";
  source = import ./script.nix {};
in stdenv.mkDerivation {
  name = name;
  script = writeScript name source;
  phases = [ "installPhase" ];
  propagatedBuildInputs = [ i3lock-fancy ];
  installPhase = ''
    mkdir -p $out/bin
    echo "$script" > $out/bin/$name
    chmod +x $out/bin/$name
  '';
}
