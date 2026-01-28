{ pkgs, ... }:
{
  imports = [
    ./globals.nix
    ./settings.nix
    ./autocmds.nix
    ./keymaps.nix
    ./performance.nix
    ./stylix.nix
    ./plugins
  ];

  extraFiles = {
    "lua/dejanr/utils.lua".source = ./lua/dejanr/utils.lua;
    "lua/dejanr/pi-mono.lua".source = ./lua/dejanr/pi-mono.lua;
  };
}
