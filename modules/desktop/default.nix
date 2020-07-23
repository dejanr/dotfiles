{ config, lib, pkgs, ... }:

{
  imports = [
    ./bspwm.nix

    ./apps
    ./term
    ./browsers
    ./gaming
  ];
}
