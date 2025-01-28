{ pkgs }:

let
  hacksaw = "${pkgs.hacksaw}/bin/hacksaw";
  ffmpeg = "${(pkgs.ffmpeg-full.override { withXcb = true; })}/bin/ffmpeg";
in
''
  #!/usr/bin/env bash

  #!/usr/bin/env bash
  #
  #   dejli-gif is a screen recorder that records a selected screen area and encodes it into a GIF.
  #
  #   Gifs are stored in ~/archive/dejli-gifs

  stty -echoctl # Don't print ^C when pressing Ctrl+C

  function log() {
    local level="$1" message="$2" exit_on_fail="''${3:-false}"
    local color=""

    case "$level" in
      ERROR) color="\033[0;31m" ;;
      SUCCESS) color="\033[0;32m" ;;
      INFO) color="\033[0;36m" ;;
    esac

    echo -e "''${color}''${level}:\033[0m $message"

    [[ "$exit_on_fail" == true ]] && exit 1
  }

  PID_FILE="/tmp/dejli-gif.pid"
  OUTPUT_FILE=$(eval echo "~/archive/dejli-gifs/$(date +%Y%m%d_%H%M%S).gif")

  mkdir -p $(dirname "$OUTPUT_FILE")

  TEMP_DIRECTORY=$(mktemp -d 2>/dev/null) || log "ERROR" "Could not create temporary directory" true
  log "INFO" "Created temporary directory $TEMP_DIRECTORY"

  function kill_previous_instances() {
    local script_name=$(basename "$0")

    local script_pids
    script_pids=$(pgrep -f "$script_name" | grep -vw "$$") # Exclude the current script's process ID

    if [[ -n "$script_pids" ]]; then
      log "INFO" "Found running script instances: $script_pids"
      for pid in $script_pids; do
        log "INFO" "Stopping script process (PID: $pid)..."
        kill "$pid" 2>/dev/null
        wait "$pid" 2>/dev/null || true
      done
      log "SUCCESS" "Stopped all previous instances of $script_name."
    else
      log "INFO" "No previous script instances found."
    fi

    # Kill any leftover FFmpeg processes using the PID file
    if [[ -f "$PID_FILE" ]]; then
      local ffmpeg_pid
      ffmpeg_pid=$(cat "$PID_FILE")
      if kill -0 "$ffmpeg_pid" 2>/dev/null; then
        log "INFO" "Stopping leftover FFmpeg process (PID: $ffmpeg_pid)..."
        kill "$ffmpeg_pid" 2>/dev/null
        wait "$ffmpeg_pid" 2>/dev/null || true
        log "SUCCESS" "Stopped leftover FFmpeg process."
      else
        log "INFO" "No leftover FFmpeg process found in PID file."
      fi
      rm -f "$PID_FILE"
      log "INFO" "Removed PID file."
    fi
  }

  function get_geometry() {
    log "INFO" "Select the area to record using your mouse..."
    local raw_geometry
    raw_geometry=$(${hacksaw}) || log "ERROR" "No area selected. Exiting." true
    log "INFO" "Raw geometry: $raw_geometry"

    IFS=+x read -r w h x y <<< "$raw_geometry"
    w=$((w + w % 2))
    h=$((h + h % 2))
    [[ -z "$w" || -z "$h" || -z "$x" || -z "$y" ]] && log "ERROR" "Invalid geometry: x=$x, y=$y, width=$w, height=$h" true
    log "INFO" "Parsed geometry: x=$x, y=$y, width=$w, height=$h"
  }

  function record() {
    ${ffmpeg} -f x11grab -s "''${w}x''${h}" -i ":0.0+''${x},''${y}" \
      -vf "crop=trunc(iw/2)*2:trunc(ih/2)*2" -loglevel "quiet" -r 30 \
      -preset veryslow -crf 0 "$TEMP_DIRECTORY/intermediate.mp4" &

    FFMPEG_PID="$!"
    echo "$FFMPEG_PID" > "$PID_FILE"

    log "INFO" "Started recording (PID: $FFMPEG_PID). Press Esc to stop."

    trap stop_recording INT
    wait_for_esc
  }

  function stop_recording() {
    if [[ -n "$FFMPEG_PID" ]] && kill -0 "$FFMPEG_PID" 2>/dev/null; then
      log "INFO" "Stopping recording..."
      kill "$FFMPEG_PID"
      wait "$FFMPEG_PID" 2>/dev/null
      log "SUCCESS" "Recording saved to $TEMP_DIRECTORY/intermediate.mp4"
      FFMPEG_PID="" # Clear the PID to prevent repeated attempts
    else
      log "INFO" "Recording process already stopped."
    fi
  }

  function wait_for_esc() {
    while true; do
      # Check if PID_FILE is missing or if the process with the PID in PID_FILE is no longer running
      if [[ ! -f "$PID_FILE" ]]; then
        log "ERROR" "PID_FILE is missing. Stopping recording."
        stop_recording
        break
      fi

      local pid_in_file
      pid_in_file=$(cat "$PID_FILE" 2>/dev/null)
      if [[ -z "$pid_in_file" || ! -e /proc/"$pid_in_file" ]]; then
        log "ERROR" "Process with PID $pid_in_file is no longer running. Stopping recording."
        stop_recording
        break
      fi

      # Use non-blocking read to check for user input
      if read -t 1 -n 1 key; then
        if [[ "$key" == $'\e' ]]; then
          stop_recording
          break
        fi
      fi

      sleep 1
    done
  }

  function encode() {
    ${ffmpeg} -i "$TEMP_DIRECTORY/intermediate.mp4" \
      -vf "split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
      "$TEMP_DIRECTORY/final.gif" || log "ERROR" "Failed to encode GIF" true
    log "SUCCESS" "Encoded final GIF to $TEMP_DIRECTORY/final.gif"
  }

  function deliver() {
    mv "$TEMP_DIRECTORY/final.gif" "$OUTPUT_FILE" || log "ERROR" "Failed to save final GIF" true
    log "SUCCESS" "Final GIF saved to $OUTPUT_FILE"

    echo -n "file://$OUTPUT_FILE" | xclip -sel clip -t text/uri-list || log "ERROR" "Failed to copy GIF URI to clipboard" false
    log "SUCCESS" "GIF copied to clipboard"
  }

  function cleanup() {
    rm -rf "$TEMP_DIRECTORY"
    rm -f "$PID_FILE"
    log "INFO" "Deleted temporary directory $TEMP_DIRECTORY"
  }

  function main() {
    kill_previous_instances
    get_geometry
    record
    encode
    deliver
    cleanup
    exit 0
  }

  main
''
