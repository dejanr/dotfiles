{ pkgs }:

let
  ffmpeg = "${pkgs.ffmpeg-full}/bin/ffmpeg";
  pactl = "${pkgs.pulseaudio}/bin/pactl";
  notify-send = "${pkgs.libnotify}/bin/notify-send";
  xclip = "${pkgs.xclip}/bin/xclip";
in
''
  #!/usr/bin/env bash
  #
  #   dejli-audio — records mic + system output into a combined audio file.
  #
  #   Usage:
  #     dejli-audio              Record using default source + default sink monitor
  #     dejli-audio --toggle     Stop if already recording, start otherwise (for keybinds)
  #     dejli-audio --list       List available audio sources
  #     dejli-audio --source X   Record using source X instead of default
  #
  #   Audio is stored in ~/archive/dejli-audio

  stty -echoctl 2>/dev/null || true

  PID_FILE="/tmp/dejli-audio.pid"
  ARCHIVE_DIR="$HOME/archive/dejli-audio"
  OUTPUT_FILE="$ARCHIVE_DIR/$(date +%Y%m%d_%H%M%S).wav"
  SOURCE_OVERRIDE=""
  TOGGLE_MODE=false

  function log() {
    local level="$1" message="$2"
    local color=""
    case "$level" in
      ERROR)   color="\033[0;31m" ;;
      SUCCESS) color="\033[0;32m" ;;
      INFO)    color="\033[0;36m" ;;
    esac
    echo -e "''${color}''${level}:\033[0m $message"
  }

  function notify() {
    ${notify-send} -a "dejli-audio" "$1" "$2" 2>/dev/null || true
  }

  function list_sources() {
    echo "Available audio sources:"
    ${pactl} list sources short 2>/dev/null | while read -r id name driver fmt state; do
      local desc
      desc=$(${pactl} list sources 2>/dev/null | grep -A1 "Name: $name" | grep "Description:" | sed 's/.*Description: //')
      printf "  %-60s %s\n" "$name" "$desc"
    done
  }

  function is_recording() {
    [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null
  }

  function stop_existing() {
    if [[ -f "$PID_FILE" ]]; then
      local pid
      pid=$(cat "$PID_FILE")
      if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null || true
        log "SUCCESS" "Stopped recording (PID: $pid)"
        notify "Recording stopped" "Audio saved"
      fi
      rm -f "$PID_FILE"
    fi
  }

  function kill_previous_instances() {
    local script_name
    script_name=$(basename "$0")
    local pids
    pids=$(pgrep -f "$script_name" | grep -vw "$$" || true)

    for pid in $pids; do
      kill "$pid" 2>/dev/null
      wait "$pid" 2>/dev/null || true
    done

    stop_existing
  }

  function record() {
    local mic_source
    mic_source="''${SOURCE_OVERRIDE:-$(${pactl} get-default-source 2>/dev/null)}"
    local output_monitor
    output_monitor="$(${pactl} get-default-sink 2>/dev/null).monitor"

    if [[ -z "$mic_source" ]]; then
      log "ERROR" "No mic source found"
      notify "Recording failed" "No mic source found"
      exit 1
    fi

    mkdir -p "$ARCHIVE_DIR"

    log "INFO" "Mic: $mic_source"
    log "INFO" "Output: $output_monitor"
    notify "Recording started" "Mic: $mic_source\nPress Esc to stop"

    ${ffmpeg} \
      -loglevel quiet \
      -f pulse -i "$mic_source" \
      -f pulse -i "$output_monitor" \
      -filter_complex "amix=inputs=2:duration=longest" \
      -y "$OUTPUT_FILE" &

    local ffmpeg_pid="$!"
    echo "$ffmpeg_pid" > "$PID_FILE"

    log "INFO" "Recording (PID: $ffmpeg_pid). Press Esc to stop."

    trap 'stop_recording' INT TERM
    wait_for_stop "$ffmpeg_pid"
  }

  function stop_recording() {
    if [[ -f "$PID_FILE" ]]; then
      local pid
      pid=$(cat "$PID_FILE")
      if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null || true
      fi
      rm -f "$PID_FILE"
    fi

    if [[ -f "$OUTPUT_FILE" && -s "$OUTPUT_FILE" ]]; then
      log "SUCCESS" "Saved: $OUTPUT_FILE"
      echo -n "file://$OUTPUT_FILE" | ${xclip} -sel clip -t text/uri-list 2>/dev/null || true
      notify "Recording saved" "$OUTPUT_FILE"
    else
      log "ERROR" "Recording produced no output"
      notify "Recording failed" "No output file"
    fi
  }

  function wait_for_stop() {
    local pid="$1"
    while kill -0 "$pid" 2>/dev/null; do
      if read -t 1 -n 1 key 2>/dev/null; then
        if [[ "$key" == $'\e' ]]; then
          stop_recording
          return
        fi
      fi
    done
    # ffmpeg exited on its own
    stop_recording
  }

  function parse_args() {
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --toggle)  TOGGLE_MODE=true; shift ;;
        --list)    list_sources; exit 0 ;;
        --source)  SOURCE_OVERRIDE="$2"; shift 2 ;;
        -h|--help)
          echo "Usage: dejli-audio [--toggle] [--list] [--source NAME]"
          exit 0
          ;;
        *) log "ERROR" "Unknown option: $1"; exit 1 ;;
      esac
    done
  }

  function main() {
    parse_args "$@"

    if [[ "$TOGGLE_MODE" == true ]] && is_recording; then
      stop_existing
      exit 0
    fi

    kill_previous_instances
    record
  }

  main "$@"
''
