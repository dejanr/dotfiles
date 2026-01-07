{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.darwin.gui.aerospace;
in
{
  options.modules.darwin.gui.aerospace = {
    enable = mkEnableOption "aerospace";
  };

  config = mkIf cfg.enable {
    programs.aerospace = {
      enable = true;
      package = pkgs.aerospace;

      launchd.enable = true;

      settings = {
        default-root-container-layout = "tiles";
        default-root-container-orientation = "horizontal";
        enable-normalization-flatten-containers = false;
        enable-normalization-opposite-orientation-for-nested-containers = false;

        gaps = {
          inner = {
            horizontal = 0;
            vertical = 0;
          };
          outer = {
            left = 0;
            bottom = 0;
            top = 0;
            right = 0;
          };
        };

        mode.main.binding = {
          cmd-shift-j = "focus down";
          cmd-shift-k = "focus up";
          cmd-shift-l = "focus right";
          cmd-shift-h = "focus left";

          cmd-alt-j = "move down";
          cmd-alt-k = "move up";
          cmd-alt-l = "move right";
          cmd-alt-h = "move left";

          cmd-shift-f = "fullscreen";
          cmd-shift-m = "layout floating tiling";

          cmd-1 = "workspace 1";
          cmd-2 = "workspace 2";
          cmd-3 = "workspace 3";
          cmd-4 = "workspace 4";
          cmd-5 = "workspace 5";

          cmd-shift-1 = [
            "move-node-to-workspace 1"
            "workspace 1"
          ];
          cmd-shift-2 = [
            "move-node-to-workspace 2"
            "workspace 2"
          ];
          cmd-shift-3 = [
            "move-node-to-workspace 3"
            "workspace 3"
          ];
          cmd-shift-4 = [
            "move-node-to-workspace 4"
            "workspace 4"
          ];
          cmd-shift-5 = [
            "move-node-to-workspace 5"
            "workspace 5"
          ];

          cmd-alt-x = "reload-config";
        };

        on-window-detected = [
          {
            "if".app-id = "com.google.Chrome";
            run = "layout floating";
          }
          {
            "if".app-id = "com.apple.finder";
            run = "layout floating";
          }
          {
            "if".app-name-regex-substring = "1Password";
            run = "layout floating";
          }
          {
            "if".app-name-regex-substring = "Calendar";
            run = ["layout floating" "move-node-to-workspace 4"];
          }
          {
            "if".app-name-regex-substring = "Simulator";
            run = "layout floating";
          }
          {
            "if".app-name-regex-substring = "Messages";
            run = ["layout floating" "move-node-to-workspace 5"];
          }
          {
            "if".app-name-regex-substring = "Slack";
            run = ["layout floating" "move-node-to-workspace 5"];
          }
        ];
      };
    };
  };
}
