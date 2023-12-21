{ ... }:

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
}
