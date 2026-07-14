{
  lib,
  config,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.geforce-now;

  python = pkgs.python3.withPackages (pythonPackages: [
    pythonPackages.websocket-client
  ]);

  keepalive = pkgs.writeShellApplication {
    name = "geforce-now-keepalive";
    runtimeInputs = [
      pkgs.libnotify
      pkgs.niri
      pkgs.ydotool
    ];
    text = ''
      exec ${python}/bin/python3 ${./geforce-now/keepalive.py} "$@"
    '';
  };

  chrome = pkgs.writeShellApplication {
    name = "geforce-now-chrome";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.google-chrome
    ];
    text = ''
      url="''${1:-https://play.geforcenow.com}"
      if [ "$#" -gt 0 ]; then
        shift
      fi

      profile_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/geforce-now-chrome"
      mkdir -p "$profile_dir"

      exec google-chrome-stable \
        --user-data-dir="$profile_dir" \
        --remote-debugging-address=127.0.0.1 \
        --remote-debugging-port=9222 \
        --remote-allow-origins=http://127.0.0.1:9222 \
        --no-first-run \
        --no-default-browser-check \
        --ozone-platform-hint=auto \
        "$@" \
        --app="$url"
    '';
  };

  launcher = pkgs.writeShellApplication {
    name = "geforce-now";
    runtimeInputs = [
      chrome
      keepalive
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = ''
      log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/geforce-now"
      lock_dir="''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/geforce-now"
      mkdir -p "$log_dir" "$lock_dir"

      (
        flock -n 9 || exit 0
        exec geforce-now-keepalive
      ) 9>"$lock_dir/keepalive.lock" >>"$log_dir/keepalive.log" 2>&1 &

      exec geforce-now-chrome "$@"
    '';
  };
in
{
  options.modules.home.gui.geforce-now = {
    enable = mkEnableOption "GeForce NOW helpers";
  };

  config = mkIf cfg.enable {
    home.packages = [
      chrome
      keepalive
      launcher
    ];

    xdg.desktopEntries.geforce-now = {
      name = "GeForce NOW";
      exec = "geforce-now";
      terminal = false;
      categories = [ "Game" ];
    };
  };
}
