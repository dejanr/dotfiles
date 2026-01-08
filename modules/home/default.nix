{
  pkgs,
  inputs,
  importsFrom,
  ...
}:

{
  home.stateVersion = "23.11";

  nix.registry = {
    nixpkgs.flake = inputs.nixpkgs;
  };

  nix.package = pkgs.nix;

  nix.settings = {
    experimental-features = "nix-command flakes";
    nix-path = [ "nixpkgs=${inputs.nixpkgs.outPath}" ];
  };

  imports = importsFrom {
    path = ./.;
    exclude = [
      "config.nix"
      ./cli/nixvim
      ./cli/pi-mono/extensions
      ./cli/pi-mono/nix
      ./cli/pi-mono/prompts
    ];
  };
}
