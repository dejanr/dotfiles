{ ... }:

{
  imports = [ ../../modules/default.nix ];

  config.modules = {
    # gui

    # cli
    git.enable = true; 
    nvim.enable = true;
    tmux.enable = true; 
    zsh.enable = true; 

    # system
    packages.enable = true;
  };
}
