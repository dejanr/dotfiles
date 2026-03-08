{
  lib,
  config,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.niri;

  dejliNiriShortcutsStatePath = "${config.home.homeDirectory}/.local/state/dejli/niri-shortcuts.kdl";
  dejliNiriShortcutsDefault = ''
    binds {
        Mod+O repeat=false hotkey-overlay-title="Toggle dejli" { spawn "dejli-desktop" "--toggle"; }
        Mod+Shift+I repeat=false hotkey-overlay-title="dejli insert voice toggle" { spawn "dejli-desktop" "--voice-insert-toggle"; }
    }
  '';

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

  dmsShellIpcScript = pkgs.writeShellScriptBin "dms-shell-ipc" ''
    set -eu

    runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    qs_bin="${pkgs.quickshell}/bin/qs"

    newest_pid_file="$(find "$runtime_dir" -maxdepth 1 -type f -name 'danklinux-*.pid' -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR == 1 { print $2 }')"

    if [ -z "$newest_pid_file" ]; then
      echo "No DMS Quickshell pid file found in $runtime_dir" >&2
      exit 1
    fi

    qs_pid="$(cat "$newest_pid_file")"

    if ! kill -0 "$qs_pid" 2>/dev/null; then
      echo "DMS Quickshell pid $qs_pid is not running" >&2
      exit 1
    fi

    exec "$qs_bin" ipc --pid "$qs_pid" call "$@"
  '';

  dejliDesktopScript = pkgs.writeShellScriptBin "dejli-desktop" ''
    exec /home/dejanr/projects/dejli/frontend/desktop/src/target/release/dejli-desktop "$@"
  '';

  defaultsSource =
    file:
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
      dmsShellIpcScript
      dejliDesktopScript
    ];

    home.sessionVariables = mkIf cfg.setSessionVariables {
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    home.activation.ensureDejliNiriShortcuts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            state_file="${dejliNiriShortcutsStatePath}"
            state_dir="$(dirname "$state_file")"
            mkdir -p "$state_dir"
            if [ ! -f "$state_file" ]; then
              cat > "$state_file" <<'EOF'
      ${dejliNiriShortcutsDefault}
      EOF
            fi
    '';

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
      "niri/dejli/shortcuts.kdl" = {
        force = true;
        source = config.lib.file.mkOutOfStoreSymlink dejliNiriShortcutsStatePath;
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
