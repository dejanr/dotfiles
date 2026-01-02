{ pkgs, ... }:

{
  imports = [ ../../modules/home/default.nix ];

  config.modules = {
    # gui
    home.gui.desktop.enable = true;

    # apps
    apps.kitty.enable = true;
    apps.kitty.fontSize = "14.0";

    # cli
    home.cli.direnv.enable = true;
    home.cli.git.enable = true;
    home.cli.dev.enable = true;
    home.cli.nixvim.enable = true;
    home.cli.tmux.enable = true;
    home.cli.zsh.enable = true;

    # system
    home.common.packages.enable = true;
  };
}
