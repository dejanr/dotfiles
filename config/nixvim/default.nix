{ pkgs, ... }:
{
  imports = [
    ./globals.nix
    ./settings.nix
    ./autocmds.nix
    ./keymaps.nix
    ./stylix.nix
    ./plugins
  ];

  extraFiles = {
    "lua/dejanr/utils.lua".source = ./lua/dejanr/utils.lua;
  };
}
