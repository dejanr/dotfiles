let
  pkgs = import <nixpkgs> {};
in
  pkgs.mkShell {
    buildInputs = import ./nix/inputs.nix;

    shellHook = ''
      export PATH="./result/bin:$PATH"
    '';
  }
