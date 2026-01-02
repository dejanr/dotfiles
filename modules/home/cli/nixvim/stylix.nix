{ config, lib, ... }:
with lib;
{
  config = mkIf (config.stylix.enable or false) {
    colorschemes.catppuccin.enable = mkForce false;
  };
}
