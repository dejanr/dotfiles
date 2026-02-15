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

    autostart = mkOption {
      type = types.attrsOf (types.submodule ({ name, ... }: {
        options = {
          name = mkOption {
            type = types.str;
            default = name;
            description = "Display name for the autostart entry";
          };

          exec = mkOption {
            type = types.str;
            description = "Command to run at session start";
          };

          terminal = mkOption {
            type = types.bool;
            default = false;
            description = "Run autostart command in a terminal";
          };

          enabled = mkOption {
            type = types.bool;
            default = true;
            description = "Whether this autostart entry is enabled";
          };
        };
      }));
      default = { };
      description = "XDG autostart desktop entries";
    };
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

    xdg.configFile = {
      "xdg-desktop-portal-termfilechooser/config" = {
        force = true;
        text = ''
          [filechooser]
          cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
        '';
      };
    }
    // mapAttrs' (entryName: entry:
      nameValuePair "autostart/${entryName}.desktop" {
        text = ''
          [Desktop Entry]
          Type=Application
          Name=${entry.name}
          Exec=${entry.exec}
          Terminal=${if entry.terminal then "true" else "false"}
          X-GNOME-Autostart-enabled=${if entry.enabled then "true" else "false"}
        '';
      }
    ) cfg.autostart;
  };
}
