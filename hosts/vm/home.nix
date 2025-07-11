{ config, lib, inputs, ... }:

{
  imports = [ ../../modules/home/default.nix ];

  config.modules = {
    # gui
    home.gui.desktop.enable = true;

    # cli
    home.cli.git.enable = true;
    home.cli.bash.enable = true;
    home.cli.dev.enable = true;
    home.cli.tmux.enable = true;

    # system
  };
}
