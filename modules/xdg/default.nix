{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.xdg;

in {
  options.modules.xdg = { enable = mkEnableOption "xdg"; };

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
