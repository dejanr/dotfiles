{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "lg-tv-input";

  runtimeInputs = with pkgs; [
    coreutils
    jq
    websocat
  ];

  text = ''
    set -euo pipefail

    usage() {
      echo "Usage: lg-tv-input --host HOST HDMI_1|HDMI_2|HDMI_3|HDMI_4" >&2
    }

    host=""
    input=""

    while [[ "$#" -gt 0 ]]; do
      case "$1" in
        --host)
          if [[ "$#" -lt 2 ]]; then
            usage
            exit 2
          fi
          host="$2"
          shift 2
          ;;
        -h|--help)
          usage
          exit 0
          ;;
        HDMI_1|HDMI_2|HDMI_3|HDMI_4)
          input="$1"
          shift
          ;;
        *)
          usage
          exit 2
          ;;
      esac
    done

    if [[ -z "$host" || -z "$input" ]]; then
      usage
      exit 2
    fi

    key_file="''${LG_TV_INPUT_KEY_FILE:-/var/lib/lg-tv-input/client-key.json}"
    signature="eyJhbGdvcml0aG0iOiJSU0EtU0hBMjU2Iiwia2V5SWQiOiJ0ZXN0LXNpZ25pbmctY2VydCIsInNpZ25hdHVyZVZlcnNpb24iOjF9.hrVRgjCwXVvE2OOSpDZ58hR+59aFNwYDyjQgKk3auukd7pcegmE2CzPCa0bJ0ZsRAcKkCTJrWo5iDzNhMBWRyaMOv5zWSrthlf7G128qvIlpMT0YNY+n/FaOHE73uLrS/g7swl3/qH/BGFG2Hu4RlL48eb3lLKqTt2xKHdCs6Cd4RMfJPYnzgvI4BNrFUKsjkcu+WD4OO2A27Pq1n50cMchmcaXadJhGrOqH5YmHdOCj5NSHzJYrsW0HPlpuAx/ECMeIZYDh6RMqaFM2DXzdKX9NmmyqzJ3o/0lkk/N97gfVRLW5hA29yeAwaCViZNCP8iC9aO0q9fQojoa7NQnAtw=="

    load_client_key() {
      if [[ -f "$key_file" ]]; then
        jq -r --arg host "$host" '.[$host] // empty' "$key_file"
      fi
    }

    save_client_key() {
      local client_key="$1"
      local key_dir temporary_file

      key_dir="$(dirname "$key_file")"
      mkdir -p "$key_dir"
      temporary_file="$(mktemp "$key_dir/client-key.XXXXXX")"
      chmod 600 "$temporary_file"

      if [[ -f "$key_file" ]]; then
        jq --arg host "$host" --arg clientKey "$client_key" '. + {($host): $clientKey}' "$key_file" > "$temporary_file"
      else
        jq -n --arg host "$host" --arg clientKey "$client_key" '{($host): $clientKey}' > "$temporary_file"
      fi

      mv "$temporary_file" "$key_file"
    }

    registration_message() {
      local client_key="$1"

      jq -cn --arg clientKey "$client_key" --arg signature "$signature" '
        {
          type: "register",
          id: "register_0",
          payload: {
            forcePairing: false,
            pairingType: "PROMPT",
            manifest: {
              appVersion: "1.1",
              manifestVersion: 1,
              permissions: [
                "LAUNCH",
                "CONTROL_INPUT_TV",
                "READ_INPUT_DEVICE_LIST",
                "READ_RUNNING_APPS"
              ],
              signatures: [{ signature: $signature, signatureVersion: 1 }],
              signed: {
                appId: "com.lge.test",
                created: "20140509",
                localizedAppNames: { "": "LG Remote App" },
                localizedVendorNames: { "": "LG Electronics" },
                permissions: ["TEST_SECURE", "CONTROL_POWER", "READ_RUNNING_APPS"],
                serial: "2f930e2d2cfe083771f68e4fe7bb07",
                vendorId: "com.lge"
              }
            }
          }
        }
        | if $clientKey != "" then .payload["client-key"] = $clientKey else . end
      '
    }

    switch_message() {
      local app_id="com.webos.app.hdmi''${input#HDMI_}"

      jq -cn --arg appId "$app_id" '{
        type: "request",
        id: "switch_input_0",
        uri: "ssap://system.launcher/launch",
        payload: { id: $appId }
      }'
    }

    send_message() {
      local message="$1"
      printf '%s\n' "$message" >&"''${WS[1]}"
    }

    read_message() {
      local timeout="$1"
      IFS= read -r -t "$timeout" message <&"''${WS[0]}"
    }

    cleanup_websocket() {
      if [[ -n "''${WS_PID:-}" ]]; then
        kill "$WS_PID" 2>/dev/null || true
        wait "$WS_PID" 2>/dev/null || true
      fi
    }

    register_tv() {
      local client_key="$1"
      local message_type message_id pairing_type return_value paired_key error_text

      send_message "$(registration_message "$client_key")"

      while read_message 60; do
        message_type="$(jq -r '.type // ""' <<< "$message")"

        if [[ "$message_type" == "registered" ]]; then
          paired_key="$(jq -r '.payload["client-key"] // empty' <<< "$message")"
          if [[ -n "$paired_key" ]]; then
            save_client_key "$paired_key"
          fi
          return 0
        fi

        if [[ "$message_type" == "error" ]]; then
          error_text="$(jq -r '.payload.errorText // .payload.error // .' <<< "$message")"
          echo "LG TV registration failed: $error_text" >&2
          return 1
        fi

        message_id="$(jq -r '.id // ""' <<< "$message")"
        if [[ "$message_id" == "register_0" ]]; then
          pairing_type="$(jq -r '.payload.pairingType // ""' <<< "$message")"
          return_value="$(jq -r '.payload.returnValue // empty' <<< "$message")"

          if [[ "$pairing_type" == "PROMPT" ]]; then
            echo "Accept the LG TV pairing prompt to continue." >&2
          fi

          if [[ "$return_value" == "false" ]]; then
            error_text="$(jq -r '.payload.errorText // .payload.error // .' <<< "$message")"
            echo "LG TV registration failed: $error_text" >&2
            return 1
          fi

          if [[ "$return_value" == "true" && -n "$client_key" && -z "$pairing_type" ]]; then
            return 0
          fi
        fi
      done

      echo "Timed out waiting for LG TV registration" >&2
      return 1
    }

    wait_for_switch_response() {
      local message_type message_id return_value error_text

      while read_message 10; do
        message_id="$(jq -r '.id // ""' <<< "$message")"
        if [[ "$message_id" != "switch_input_0" ]]; then
          continue
        fi

        message_type="$(jq -r '.type // ""' <<< "$message")"
        return_value="$(jq -r '.payload.returnValue // empty' <<< "$message")"

        if [[ "$message_type" == "error" || "$return_value" == "false" ]]; then
          error_text="$(jq -r '.payload.errorText // .payload.error // .' <<< "$message")"
          echo "LG TV input switch failed: $error_text" >&2
          return 1
        fi

        return 0
      done

      echo "Timed out waiting for LG TV input switch response" >&2
      return 1
    }

    try_uri() {
      local uri="$1"
      local client_key

      client_key="$(load_client_key)"
      coproc WS { websocat -k -t -B 1048576 "$uri"; }

      if register_tv "$client_key" && send_message "$(switch_message)" && wait_for_switch_response; then
        cleanup_websocket
        return 0
      fi

      cleanup_websocket
      return 1
    }

    if try_uri "wss://$host:3001" || try_uri "ws://$host:3000"; then
      echo "Switched LG TV $host to $input"
      exit 0
    fi

    echo "Unable to switch LG TV $host to $input" >&2
    exit 1
  '';
}
