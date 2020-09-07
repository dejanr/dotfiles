# modules/dev --- common settings for dev modules

{ pkgs, ... }: {
  imports = [ ./node.nix ./python.nix ./rust.nix ];

  options = { };
  config = { };
}
