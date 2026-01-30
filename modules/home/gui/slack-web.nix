{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.slack-web;
in
{
  options.modules.home.gui.slack-web = {
    enable = mkEnableOption "Slack web app launcher";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.firefox ];

    xdg.desktopEntries.slack = {
      name = "Slack";
      genericName = "Messaging";
      exec = "firefox --class=Slack --new-window https://app.slack.com/client";
      icon = "slack";
      terminal = false;
      categories = [ "Network" "InstantMessaging" ];
    };
  };
}
