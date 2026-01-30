{ pkgs, ... }:

{
  imports = [ ../../modules/home/default.nix ];

  # TODO: move this, reorganize
  config.home.file."npmrc".text = ''
    prefix = ~/.npm-packages
  '';
  config.home.file."npmrc".target = ".npmrc";

  config.home.packages = [ ];

  # Scaling for 4K OLED TV
  config.home.sessionVariables = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
    QT_SCALE_FACTOR = "1.5";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  };

  # Qutebrowser zoom for 4K
  config.programs.qutebrowser.settings = {
    zoom.default = "150%";
  };

  config.modules = {
    home.common.packages.enable = true;

    # secrets
    home.secrets.agenix.enable = true;

    # gui
    home.gui.xdg.enable = true;
    home.gui.desktop.enable = true;
    home.gui.games.enable = true;
    home.gui.browser.qutebrowser.enable = true;
    home.gui.slack-web.enable = true;
    home.gui.grobi = {
      enable = true;
      rules = [
        {
          name = "LG OLED TV";
          outputs_connected = [ "HDMI-1" ];
          configure_single = "HDMI-1@3840x2160";
          primary = true;
          atomic = true;
        }
      ];
    };

    # apps
    apps.kitty.enable = true;
    apps.ghostty.enable = true;

    # cli
    home.cli.direnv.enable = true;
    home.cli.git.enable = true;
    home.cli.dev.enable = true;
    home.cli.nixvim.enable = true;
    home.cli.tmux.enable = true;
    home.cli.zsh.enable = true;
    home.cli.yazi.enable = true;
    home.cli.pi-mono.enable = true;
  };

  config.home.stylix.theme = "catppuccin-mocha";
}
