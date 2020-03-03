# emacs with init.el baked in

{ emacsWithPackages, epkgs, symlinkJoin, makeWrapper }:

let

  my-emacs = emacsWithPackages (epkgs: (with epkgs; [
    evil
    evil-org
    key-chord
    linum-relative
    markdown-mode
    org
    org-pomodoro
    spaceline
    color-theme-sanityinc-tomorrow
    which-key
  ]));

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

