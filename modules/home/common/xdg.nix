{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.home.common.xdg;

in {
  options.modules.home.common.xdg = { enable = mkEnableOption "common xdg settings"; };

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
  };
}
