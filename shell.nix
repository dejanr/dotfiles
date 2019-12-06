let
  pkgs = import <nixpkgs> {};
  dotfiles = import ./default.nix {};
in
  pkgs.mkShell {
    buildInputs = [
      dotfiles
    ];

    shellHook = ''
      export PATH="./result/bin:$PATH"
    '';
  }
