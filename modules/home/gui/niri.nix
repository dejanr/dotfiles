{
  lib,
  config,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.niri;

  toggleTwoPaneScript = pkgs.writeShellScriptBin "niri-toggle-two-pane" ''
    set -eu

    NIRI="${pkgs.niri}/bin/niri"
    JQ="${pkgs.jq}/bin/jq"

    ws_id="$($NIRI msg -j windows | $JQ -r '.[] | select(.is_focused) | .workspace_id')"
    out_name="$($NIRI msg -j workspaces | $JQ -r --argjson ws "$ws_id" '.[] | select(.id == $ws) | .output')"
    col_w="$($NIRI msg -j windows | $JQ -r '.[] | select(.is_focused) | .layout.tile_size[0]')"
    out_w="$($NIRI msg -j outputs | $JQ -r --arg out "$out_name" '.[$out].logical.width')"
    col_count="$($NIRI msg -j windows | $JQ -r --argjson ws "$ws_id" '[.[] | select(.workspace_id == $ws and (.is_floating | not)) | .layout.pos_in_scrolling_layout[0]] | unique | length')"

    if awk "BEGIN { exit !($col_w > ($out_w * 0.45) && $col_w < ($out_w * 0.55)) }"; then
      # 50% -> maximized
      $NIRI msg action focus-column-first
      $NIRI msg action maximize-column
    else
      # non-50% -> 50/50
      $NIRI msg action focus-column-first
      $NIRI msg action set-column-width "50%"

      if [ "$col_count" -ge 2 ]; then
        $NIRI msg action focus-column-right
        $NIRI msg action set-column-width "50%"
        $NIRI msg action focus-column-first
      fi
    fi
  '';

  toggleFloatingCenteredScript = pkgs.writeShellScriptBin "niri-toggle-floating-centered" ''
    set -eu

    NIRI="${pkgs.niri}/bin/niri"
    JQ="${pkgs.jq}/bin/jq"

    is_floating="$($NIRI msg -j windows | $JQ -r '.[] | select(.is_focused) | .is_floating')"

    if [ "$is_floating" = "true" ]; then
      $NIRI msg action move-window-to-tiling
    else
      $NIRI msg action move-window-to-floating
      $NIRI msg action set-window-width "70%"
      $NIRI msg action set-window-height "70%"
      $NIRI msg action center-window
    fi
  '';

  defaultsSource = file:
    if cfg.defaultsOutOfStore then
      config.lib.file.mkOutOfStoreSymlink "${cfg.defaultsDirectory}/${file}"
    else
      ./. + "/niri/dms/defaults/${file}";
in
{
  options.modules.home.gui.niri = {
    enable = mkEnableOption "niri";

    configFile = mkOption {
      type = types.path;
      default = ./niri/config.kdl;
    };

    bindsFile = mkOption {
      type = types.path;
      default = ./niri/dms/binds.kdl;
    };

    windowRulesFile = mkOption {
      type = types.path;
      default = ./niri/dms/windowrules.kdl;
    };

    defaultsOutOfStore = mkOption {
      type = types.bool;
      default = false;
    };

    defaultsDirectory = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/.dotfiles/modules/home/gui/niri/dms/defaults";
    };

    setSessionVariables = mkOption {
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [
      toggleTwoPaneScript
      toggleFloatingCenteredScript
    ];

    home.sessionVariables = mkIf cfg.setSessionVariables {
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    xdg.configFile = {
      "niri/config.kdl" = {
        force = true;
        source = cfg.configFile;
      };
      "niri/dms/binds.kdl" = {
        force = true;
        source = cfg.bindsFile;
      };
      "niri/dms/windowrules.kdl" = {
        force = true;
        source = cfg.windowRulesFile;
      };

      "niri/dms/defaults/layout.kdl" = {
        force = true;
        source = defaultsSource "layout.kdl";
      };
      "niri/dms/defaults/alttab.kdl" = {
        force = true;
        source = defaultsSource "alttab.kdl";
      };
      "niri/dms/defaults/colors.kdl" = {
        force = true;
        source = defaultsSource "colors.kdl";
      };
      "niri/dms/defaults/outputs.kdl" = {
        force = true;
        source = defaultsSource "outputs.kdl";
      };
      "niri/dms/defaults/wpblur.kdl" = {
        force = true;
        source = defaultsSource "wpblur.kdl";
      };
      "niri/dms/defaults/cursor.kdl" = {
        force = true;
        source = defaultsSource "cursor.kdl";
      };
    };
  };
}
