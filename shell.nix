{ pkgs }: {
  default = pkgs.mkShell {
    nativeBuildInputs = with pkgs; [
      home-manager # A Nix-based user environment configurator
      sops # Simple and flexible tool for managing secrets
      gnupg # Modern release of the GNU Privacy Guard, a GPL OpenPGP implementation
      age # Modern encryption tool with small explicit keys
    ];
  };
}
