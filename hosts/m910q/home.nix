{ config, lib, inputs, ... }:

{
  imports = [ ../../modules/default.nix ];

  config.modules = {
    # secrets
    sops.enable = true;

    # cli
    git.enable = true;
    zsh.enable = true;
    tmux.enable = true;
    nvim.enable = true;
    direnv.enable = true;

    # system
    packages.enable = true;
  };
}
