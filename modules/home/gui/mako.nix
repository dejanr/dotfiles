{ config
, lib
, ...
}:

with lib;
let
  cfg = config.modules.home.gui.mako;

in
{
  options.modules.home.gui.mako = {
    enable = mkEnableOption "Notification daemon for wayland";
  };

  config = mkIf cfg.enable {
    services.mako = {
      enable = true;
      settings = {
        border-size = 3;
        default-timeout = 6000;
        font = "PragmataPro 12";
      };
    }; # END mako
  };
}
