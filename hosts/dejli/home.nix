{ pkgs, ... }:

{
  imports = [ ../../modules/home/default.nix ];

  # TODO: move this, reorganize
  config.home.file."npmrc".text = ''
    prefix = ~/.npm-packages
  '';
  config.home.file."npmrc".target = ".npmrc";

  config.services.ollama.enable = true;

  config.modules = {
    home.common.packages.enable = true;

    # secrets
    home.secrets.agenix.enable = true;

    # gui
    home.gui.xdg.enable = true;
    home.gui.desktop.enable = true;
    home.gui.browser.qutebrowser.enable = true;

    # apps
    apps.kitty.enable = true;

    # cli
    home.cli.direnv.enable = true;
    home.cli.git.enable = true;
    home.cli.jujutsu.enable = true;
    home.cli.dev.enable = true;
    home.cli.nvim.enable = true;
    home.cli.tmux.enable = true;
    home.cli.zsh.enable = true;
    home.cli.yazi.enable = true;
    home.cli.opencode.enable = true;
  };

  config.home.stylix = {
    enable = true;
    theme = "catppuccin-mocha";
  };
}
