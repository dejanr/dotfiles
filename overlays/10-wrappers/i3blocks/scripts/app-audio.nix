{ }: # bash
''
  #!/usr/bin/env bash

  PATTERN="''${1:-Chrome}"
  TITLE="''${2:-chrome}"

  MUTED_ICON="🔇"
  UNMUTED_ICON="🔊"
  NO_SINK_ICON="🎮"

  DEFAULT_COLOR="#FFFFFF"
  ACTIVE_COLOR="#DBC074"

  find_sink_inputs() {
      pactl list sink-inputs | grep -B 20 -A 5 "application.name.*$PATTERN" |
      grep "Sink Input #" |
      sed 's/Sink Input #//'
  }

  is_any_muted() {
    local sink_input_ids="$1"
    while IFS= read -r sink_input_id; do
      if [[ -n "$sink_input_id" ]]; then
        if pactl list sink-inputs | grep -A 20 "Sink Input #$sink_input_id" | grep "Mute:" | grep -q "yes"; then
          return 0
        fi
      fi
    done <<< "$sink_input_ids"
    return 1
  }

  toggle_mute() {
      local sink_input_ids="$1"
      while IFS= read -r sink_input_id; do
          if [[ -n "$sink_input_id" ]]; then
              pactl set-sink-input-mute "$sink_input_id" toggle
          fi
      done <<< "$sink_input_ids"
  }

  case $BLOCK_BUTTON in
      1)
          SINK_INPUT_IDS=$(find_sink_inputs)
          if [[ -n "$SINK_INPUT_IDS" ]]; then
              toggle_mute "$SINK_INPUT_IDS"
              pkill -RTMIN+10 i3blocks
          fi
          ;;
  esac

  SINK_INPUT_IDS=$(find_sink_inputs)

  if [[ -z "$SINK_INPUT_IDS" ]]; then
    echo "$NO_SINK_ICON"
    echo "$NO_SINK_ICON"
    echo "$DEFAULT_COLOR"
  elif is_any_muted "$SINK_INPUT_IDS"; then
    echo "$MUTED_ICON $TITLE"
    echo "$MUTED_ICON $TITLE"
    echo "$ACTIVE_COLOR"
  else
    echo "$UNMUTED_ICON $TITLE"
    echo "$UNMUTED_ICON $TITLE"
    echo "$DEFAULT_COLOR"
  fi
''
