{ pkgs, agenix }: {
  default = pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      home-manager # A Nix-based user environment configurator
      gnupg # Modern release of the GNU Privacy Guard, a GPL OpenPGP implementation
      agenix.packages.${system}.agenix
    ];
  };
}
