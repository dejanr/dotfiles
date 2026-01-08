{ pkgs, piMono }:

pkgs.stdenv.mkDerivation {
  pname = "pi-mono-extension-protected-paths";
  version = "1.0.0";
  src = ./..;

  installPhase = ''
    mkdir -p $out
    cp index.ts $out/

    # Link to pi-mono's node_modules for runtime imports
    ln -s ${piMono}/lib/pi-mono/node_modules $out/node_modules
  '';
}
