{ stdenv }:

stdenv.mkDerivation rec {
  pname = "doom-emacs";
  version = "0.0.0";

  src = (import ../nix/sources.nix)."doom-emacs";

  installPhase = ''
    mkdir $out
    ln -s /home/dejanr/.local $out/.local
    cp -a * $out
  '';

  meta = with stdenv.lib; {
    description = "Doom Emacs";
    homepage = https://github.com/hlissner/doom-emacs;
    license = licenses.gpl3;
    platforms = platforms.all;
    maintainers = [
    ];
  };
}
