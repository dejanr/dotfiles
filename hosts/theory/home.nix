{ config, lib, inputs, pkgs, ... }:

{
  imports = [ ../../modules/default.nix ];

  config.modules = {
    # gui

    # cli
    direnv.enable = true;
    git.enable = true;
    nvim.enable = true;
    tmux.enable = true;
    zsh.enable = true;

    # system
    packages.enable = true;
  };

  config.services.grobi = {
      enable = true;
      rules = [{
          name = "mobile";
          configure_single = "eDP-1";
          primary = true;
          atomic = true;
          execute_after = [
              "${pkgs.xorg.xrandr}/bin/xrandr --output eDP-1 --scale 1.4x1.4"
              "${pkgs.wm-wallpaper}/bin/wm-wallpaper"
          ];
      } {
          name = "fallback";
          configure_single = "eDP-1";
      }];
  };

  config.home.pointerCursor = {
    package = pkgs.vanilla-dmz;
    name = "Vanilla-DMZ";
    size = 128;
  };
}
