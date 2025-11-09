{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.xdg;

in
{
  options.modules.home.gui.xdg = {
    enable = mkEnableOption "xdg settings";
  };

  config = mkIf cfg.enable {
    xdg.userDirs = {
      enable = true;
      desktop = "$HOME/desktop";
      documents = "$HOME/documents";
      download = "$HOME/downloads";
      music = "$HOME/documents/music";
      pictures = "$HOME/documents/pictures";
      publicShare = "$HOME/documents/public";
      templates = "$HOME/documents/templates";
      videos = "$HOME/documents/videos";
    };

    xdg.portal.config.common = {
      "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
    };
    home.sessionVariables.TERMCMD = "kitty --class=file_chooser";

    xdg.configFile."xdg-desktop-portal-termfilechooser/config" = {
      force = true;
      text = ''
        [filechooser]
        cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
      '';
    };
  };
}
