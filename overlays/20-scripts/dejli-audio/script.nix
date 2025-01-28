{ pkgs }:

let
  hacksaw = "${pkgs.hacksaw}/bin/hacksaw";
  ffmpeg = "${(pkgs.ffmpeg-full.override { withXcb = true; })}/bin/ffmpeg";
in
''
  #!/usr/bin/env bash
  #
  #   dejli-audio is an audio recorder that records a mic and output together into a combined audio.
  #
  #   Audio is stored in ~/archive/dejli-audio

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

  PID_FILE="/tmp/dejli-audio.pid"
  OUTPUT_FILE=$(eval echo "~/archive/dejli-audio/$(date +%Y%m%d_%H%M%S).wav")

  mkdir -p $(dirname "$OUTPUT_FILE")

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

  function record() {
    ${ffmpeg} \
    -loglevel "quiet" \
    -f pulse -i alsa_input.pci-0000_55_00.4.analog-stereo \
    -f pulse -i alsa_output.usb-FIIO_FiiO_K11_R2R-01.analog-stereo.monitor \
    -filter_complex "amix=inputs=2:duration=longest" \
    -y "$OUTPUT_FILE" &

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
      log "SUCCESS" "Recording saved to $OUTPUT_FILE"
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

  function deliver() {
    echo -n "file://$OUTPUT_FILE" | xclip -sel clip -t text/uri-list || log "ERROR" "Failed to copy Audio to clipboard" false
    log "SUCCESS" "Audio copied to clipboard"
  }

  function cleanup() {
    rm -rf "$TEMP_DIRECTORY"
    rm -rf "$PID_FILE"
    log "INFO" "Deleted temporary directory $TEMP_DIRECTORY"
  }

  function main() {
    kill_previous_instances
    record
    deliver
    cleanup
    exit 0
  }

  main
''
