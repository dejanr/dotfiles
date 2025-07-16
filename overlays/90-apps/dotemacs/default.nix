# emacs with init.el baked in

{
  emacsWithPackages,
  epkgs,
  symlinkJoin,
  makeWrapper,
}:
let
  my-emacs = emacsWithPackages (
    epkgs:
    (with epkgs; [
      org
      which-key
    ])
  );
in
symlinkJoin {
  name = "emacs";
  buildInputs = [ makeWrapper ];
  paths = [ my-emacs ];
  postBuild = ''
    wrapProgram "$out/bin/emacs" \
    --add-flags "-q -l ${./init.el}"
  '';
}
