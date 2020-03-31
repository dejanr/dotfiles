let
  pkgs = (import ./nix).pkgs {};
  dotfiles = import ./default.nix {};
in
pkgs.mkShell {
    src = ./default.nix;
    buildInputs = [
      dotfiles
    ];

    shellHook = ''
      export PATH="./result/bin:$PATH"
    '';
  }
