{ pkgs, ... }:
{
  imports = [
    ./globals.nix
    ./settings.nix
    ./autocmds.nix
    ./keymaps.nix
  ];

  colorschemes.catppuccin.enable = true;

  extraFiles = {
    "lua/dejanr/utils.lua".source = ./lua/dejanr/utils.lua;
  };
}
