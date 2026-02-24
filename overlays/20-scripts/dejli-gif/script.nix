{ pkgs }:

let
  ffmpeg = "${(pkgs.ffmpeg-full.override { withXcb = true; })}/bin/ffmpeg";
  wfRecorder = "${pkgs.wf-recorder}/bin/wf-recorder";
  slurp = "${pkgs.slurp}/bin/slurp";
  slop = "${pkgs.slop}/bin/slop";
  wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
  xclip = "${pkgs.xclip}/bin/xclip";
  notifySend = "${pkgs.libnotify}/bin/notify-send";
in
''
  #!/usr/bin/env bash

  set -euo pipefail

  STATE_FILE="/tmp/dejli-gif.state"
  ARCHIVE_DIR="$HOME/archive/dejli-gifs"

  action="toggle"

  notify() {
    ${notifySend} -a "dejli-gif" "$1" "$2" 2>/dev/null || true
  }

  is_recording() {
    [[ -f "$STATE_FILE" ]] || return 1
    # shellcheck disable=SC1090
    source "$STATE_FILE"
    [[ -n "''${RECORDER_PID:-}" ]] && kill -0 "''${RECORDER_PID}" 2>/dev/null
  }

  cleanup_state() {
    if [[ -f "$STATE_FILE" ]]; then
      # shellcheck disable=SC1090
      source "$STATE_FILE" || true
      if [[ -n "''${TEMP_DIR:-}" && -d "''${TEMP_DIR}" ]]; then
        rm -rf "''${TEMP_DIR}" || true
      fi
      rm -f "$STATE_FILE"
    fi
  }

  parse_args() {
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --start) action="start"; shift ;;
        --stop) action="stop"; shift ;;
        --toggle) action="toggle"; shift ;;
        -h|--help)
          echo "Usage: dejli-gif [--start|--stop|--toggle]"
          exit 0
          ;;
        *)
          echo "Unknown option: $1" >&2
          exit 1
          ;;
      esac
    done
  }

  start_recording() {
    mkdir -p "$ARCHIVE_DIR"

    local temp_dir
    temp_dir=$(mktemp -d)

    local output_file="$ARCHIVE_DIR/$(date +%Y%m%d_%H%M%S).gif"
    local intermediate="$temp_dir/intermediate.mkv"

    local mode="x11"
    local recorder_pid

    if [[ "''${XDG_SESSION_TYPE:-}" == "wayland" || -n "''${WAYLAND_DISPLAY:-}" ]]; then
      mode="wayland"
      local region
      region=$(${slurp}) || {
        rm -rf "$temp_dir"
        exit 0
      }
      [[ -n "$region" ]] || {
        rm -rf "$temp_dir"
        exit 0
      }

      ${wfRecorder} -g "$region" -f "$intermediate" >/dev/null 2>&1 &
      recorder_pid=$!
    else
      local selection
      selection=$(${slop} -f "%x %y %w %h") || {
        rm -rf "$temp_dir"
        exit 0
      }
      [[ -n "$selection" ]] || {
        rm -rf "$temp_dir"
        exit 0
      }

      local x y w h
      read -r x y w h <<< "$selection"
      w=$((w - w % 2))
      h=$((h - h % 2))

      if [[ "$w" -le 0 || "$h" -le 0 ]]; then
        rm -rf "$temp_dir"
        exit 0
      fi

      ${ffmpeg} -loglevel error -f x11grab -video_size "''${w}x''${h}" -framerate 30 -i ":0.0+''${x},''${y}" -y "$intermediate" >/dev/null 2>&1 &
      recorder_pid=$!
    fi

    cat > "$STATE_FILE" <<EOF
RECORDER_PID=$recorder_pid
MODE="$mode"
TEMP_DIR="$temp_dir"
INTERMEDIATE="$intermediate"
OUTPUT_FILE="$output_file"
EOF

    notify "GIF recording started" "Select done. Press Mod+Shift+P again to stop."
  }

  stop_recording() {
    if ! [[ -f "$STATE_FILE" ]]; then
      notify "GIF recording" "No active recording"
      exit 0
    fi

    # shellcheck disable=SC1090
    source "$STATE_FILE"

    if [[ -n "''${RECORDER_PID:-}" ]] && kill -0 "$RECORDER_PID" 2>/dev/null; then
      kill -INT "$RECORDER_PID" 2>/dev/null || true
      wait "$RECORDER_PID" 2>/dev/null || true
    fi

    if ! [[ -s "$INTERMEDIATE" ]]; then
      cleanup_state
      notify "GIF recording failed" "No video captured"
      exit 1
    fi

    ${ffmpeg} -loglevel error -y -i "$INTERMEDIATE" \
      -vf "fps=15,split[s0][s1];[s0]palettegen=max_colors=256[p];[s1][p]paletteuse=dither=floyd_steinberg" \
      "$OUTPUT_FILE"

    if [[ "''${MODE}" == "wayland" ]]; then
      printf 'file://%s\n' "$OUTPUT_FILE" | ${wlCopy} --type text/uri-list
    else
      printf 'file://%s\n' "$OUTPUT_FILE" | ${xclip} -selection clipboard -t text/uri-list
    fi

    cleanup_state
    notify "GIF saved" "$OUTPUT_FILE"
  }

  main() {
    parse_args "$@"

    if ! is_recording && [[ -f "$STATE_FILE" ]]; then
      cleanup_state
    fi

    case "$action" in
      start)
        if is_recording; then
          notify "GIF recording" "Already recording"
        else
          start_recording
        fi
        ;;
      stop)
        stop_recording
        ;;
      toggle)
        if is_recording; then
          stop_recording
        else
          start_recording
        fi
        ;;
    esac
  }

  main "$@"
''
