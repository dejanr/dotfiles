{
  lib,
  config,
  pkgs,
  osConfig ? { },
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.niri;
  dejliShortcuts = "${config.xdg.stateHome}/dejli/niri-shortcuts.kdl";

  portalNiriUnit = ''
    [Unit]
    After=niri.service
    PartOf=niri.service
  '';

  toggleTwoPaneScript = pkgs.writeShellScriptBin "niri-toggle-two-pane" ''
    set -eu

    NIRI="${cfg.package}/bin/niri"
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

    NIRI="${cfg.package}/bin/niri"
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
    exec ${lib.getExe config.programs.dank-material-shell.package} ipc call "$@"
  '';

  dejliDesktopScript = pkgs.writeShellScriptBin "dejli-desktop" ''
    exec ${lib.escapeShellArg cfg.dejliDesktopExecutable} "$@"
  '';

  managedFiles = {
    "managed/binds.kdl" = cfg.bindsFile;
    "managed/windowrules.kdl" = cfg.windowRulesFile;
    "managed/appearance.kdl" = ./niri/managed/appearance.kdl;
    "managed/dejli-shortcuts.kdl" = ./niri/dejli/shortcuts.kdl;
  };

  validatedConfig = pkgs.runCommand "niri-config" { } ''
    mkdir -p "$out/managed"
    cp ${cfg.configFile} "$out/config.kdl"
    ${concatStringsSep "\n" (
      mapAttrsToList (name: source: ''
        ln -s ${source} "$out/${name}"
      '') managedFiles
    )}
    ${lib.getExe cfg.package} validate --config "$out/config.kdl"
  '';
in
{
  options.modules.home.gui.niri = {
    enable = mkEnableOption "niri";

    package = mkOption {
      type = types.package;
      default = osConfig.programs.niri.package or pkgs.niri;
      description = "Runtime Niri package, also used for config validation and IPC helpers.";
    };

    configFile = mkOption {
      type = types.path;
      default = ./niri/config.kdl;
    };

    bindsFile = mkOption {
      type = types.path;
      default = ./niri/managed/binds.kdl;
    };

    windowRulesFile = mkOption {
      type = types.path;
      default = ./niri/managed/windowrules.kdl;
    };

    dejliDesktopExecutable = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional local development executable; leave unset for an installed dejli-desktop.";
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
    ]
    ++ optional (cfg.dejliDesktopExecutable != null) dejliDesktopScript;

    home.sessionVariables = mkIf cfg.setSessionVariables {
      XDG_CURRENT_DESKTOP = "niri";
      XDG_SESSION_DESKTOP = "niri";
      NIXOS_OZONE_WL = "1";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    };

    xdg.configFile =
      (mapAttrs' (
        name: source:
        nameValuePair "niri/${name}" {
          inherit source;
        }
      ) managedFiles)
      // {
        "niri/config.kdl".source = validatedConfig + "/config.kdl";
        "niri/dejli/shortcuts.kdl".source = config.lib.file.mkOutOfStoreSymlink dejliShortcuts;
        "systemd/user/xdg-desktop-portal.service.d/niri.conf".text = portalNiriUnit;
        "systemd/user/xdg-desktop-portal-gnome.service.d/niri.conf".text = portalNiriUnit;
      };
  };
}
