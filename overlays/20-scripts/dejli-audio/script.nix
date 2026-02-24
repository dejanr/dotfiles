{ pkgs }:

let
  ffmpeg = "${pkgs.ffmpeg-full}/bin/ffmpeg";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  notifySend = "${pkgs.libnotify}/bin/notify-send";
  wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
  xclip = "${pkgs.xclip}/bin/xclip";
in
''
  #!/usr/bin/env bash

  set -euo pipefail

  PID_FILE="/tmp/dejli-audio.pid"
  STATE_FILE="/tmp/dejli-audio.state"
  ARCHIVE_DIR="$HOME/archive/dejli-audio"

  action="toggle"
  source_override=""

  notify() {
    ${notifySend} -a "dejli-audio" "$1" "$2" 2>/dev/null || true
  }

  is_wayland() {
    [[ "''${XDG_SESSION_TYPE:-}" == "wayland" || -n "''${WAYLAND_DISPLAY:-}" ]]
  }

  copy_uri_to_clipboard() {
    local output_file="$1"
    local uri
    uri=$(printf 'file://%s\n' "$output_file")

    if is_wayland; then
      printf '%s' "$uri" | ${wlCopy} --type text/uri-list 2>/dev/null || true
    else
      printf '%s' "$uri" | ${xclip} -selection clipboard -t text/uri-list 2>/dev/null || true
    fi
  }

  cleanup_state() {
    rm -f "$PID_FILE" "$STATE_FILE"
  }

  is_recording() {
    if [[ -f "$STATE_FILE" ]]; then
      # shellcheck disable=SC1090
      source "$STATE_FILE"
      if [[ -n "''${FFMPEG_PID:-}" ]] && kill -0 "''${FFMPEG_PID}" 2>/dev/null; then
        return 0
      fi
    fi

    if [[ -f "$PID_FILE" ]]; then
      local pid
      pid=$(cat "$PID_FILE" 2>/dev/null || true)
      if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
        return 0
      fi
    fi

    return 1
  }

  list_sources() {
    echo "Available audio sources:"
    ${pactl} list sources short 2>/dev/null | awk '{print "  " $2}'
  }

  resolve_sources() {
    local mic_source sink monitor

    mic_source="''${source_override:-$(${pactl} get-default-source 2>/dev/null || true)}"
    sink="$(${pactl} get-default-sink 2>/dev/null || true)"

    if [[ -z "$mic_source" || -z "$sink" ]]; then
      echo "Could not resolve default PulseAudio source/sink" >&2
      return 1
    fi

    monitor="''${sink}.monitor"

    printf '%s\n%s\n' "$mic_source" "$monitor"
  }

  start_recording() {
    if is_recording; then
      notify "Audio recording" "Already recording"
      return 0
    fi

    mkdir -p "$ARCHIVE_DIR"

    local output_file
    output_file="$ARCHIVE_DIR/$(date +%Y%m%d_%H%M%S).wav"

    local mic_source monitor
    readarray -t resolved < <(resolve_sources)
    mic_source="''${resolved[0]:-}"
    monitor="''${resolved[1]:-}"

    if [[ -z "$mic_source" || -z "$monitor" ]]; then
      notify "Audio recording failed" "No valid source/sink monitor found"
      return 1
    fi

    ${ffmpeg} \
      -loglevel error \
      -f pulse -i "$mic_source" \
      -f pulse -i "$monitor" \
      -filter_complex "amix=inputs=2:duration=longest:dropout_transition=2" \
      -c:a pcm_s16le \
      -y "$output_file" >/dev/null 2>&1 &

    local ffmpeg_pid="$!"

    cat > "$STATE_FILE" <<EOF
FFMPEG_PID=$ffmpeg_pid
OUTPUT_FILE="$output_file"
MIC_SOURCE="$mic_source"
MONITOR_SOURCE="$monitor"
EOF

    echo "$ffmpeg_pid" > "$PID_FILE"

    notify "Audio recording started" "Mic: $mic_source"
  }

  stop_recording() {
    if ! is_recording; then
      cleanup_state
      notify "Audio recording" "No active recording"
      return 0
    fi

    local ffmpeg_pid=""
    local output_file=""

    if [[ -f "$STATE_FILE" ]]; then
      # shellcheck disable=SC1090
      source "$STATE_FILE"
      ffmpeg_pid="''${FFMPEG_PID:-}"
      output_file="''${OUTPUT_FILE:-}"
    fi

    if [[ -z "$ffmpeg_pid" && -f "$PID_FILE" ]]; then
      ffmpeg_pid=$(cat "$PID_FILE" 2>/dev/null || true)
    fi

    if [[ -n "$ffmpeg_pid" ]] && kill -0 "$ffmpeg_pid" 2>/dev/null; then
      kill -INT "$ffmpeg_pid" 2>/dev/null || true
      wait "$ffmpeg_pid" 2>/dev/null || true
    fi

    cleanup_state

    if [[ -n "$output_file" && -s "$output_file" ]]; then
      copy_uri_to_clipboard "$output_file"
      notify "Audio saved" "$output_file"
    else
      notify "Audio recording failed" "No output file"
      return 1
    fi
  }

  parse_args() {
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --start)
          action="start"
          shift
          ;;
        --stop)
          action="stop"
          shift
          ;;
        --toggle)
          action="toggle"
          shift
          ;;
        --list)
          list_sources
          exit 0
          ;;
        --source)
          source_override="$2"
          shift 2
          ;;
        -h|--help)
          echo "Usage: dejli-audio [--start|--stop|--toggle] [--source <name>] [--list]"
          exit 0
          ;;
        *)
          echo "Unknown option: $1" >&2
          exit 1
          ;;
      esac
    done
  }

  main() {
    parse_args "$@"

    if ! is_recording; then
      cleanup_state
    fi

    case "$action" in
      start)
        start_recording
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
