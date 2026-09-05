{
  colors,
  libnotify,
  systemd,
}:
''
  #!/usr/bin/env bash

  BUSCTL="${systemd}/bin/busctl"
  NOTIFY_SEND="${libnotify}/bin/notify-send"

  find_device_path() {
    local target_name=$1
    local path
    local name

    while IFS= read -r path; do
      [[ $path == /org/bluez/hci*/dev_* ]] || continue
      name=$("$BUSCTL" --system get-property org.bluez "$path" org.bluez.Device1 Name 2>/dev/null) || continue
      if [[ $name == "s \"$target_name\"" ]]; then
        printf '%s\n' "$path"
        return 0
      fi
    done < <("$BUSCTL" --system tree org.bluez --list 2>/dev/null)

    return 1
  }

  is_connected() {
    [[ $("$BUSCTL" --system get-property org.bluez "$1" org.bluez.Device1 Connected 2>/dev/null) == "b true" ]]
  }

  connect_joycons() {
    local failed=0
    local path

    for path in "$LEFT_PATH" "$RIGHT_PATH"; do
      if [[ -z $path ]]; then
        failed=1
      elif ! is_connected "$path"; then
        "$BUSCTL" --system call org.bluez "$path" org.bluez.Device1 Connect >/dev/null 2>&1 || failed=1
      fi
    done

    if ((failed)); then
      "$NOTIFY_SEND" -a i3blocks "Joy-Cons" "Wake both controllers and click again"
    else
      "$NOTIFY_SEND" -a i3blocks "Joy-Cons" "Connected; press L + R to combine"
    fi
  }

  disconnect_joycons() {
    local path

    for path in "$LEFT_PATH" "$RIGHT_PATH"; do
      if [[ -n $path ]] && is_connected "$path"; then
        "$BUSCTL" --system call org.bluez "$path" org.bluez.Device1 Disconnect >/dev/null 2>&1 || true
      fi
    done

    "$NOTIFY_SEND" -a i3blocks "Joy-Cons" "Disconnected"
  }

  has_combined_gamepad() {
    local line

    while IFS= read -r line; do
      [[ $line == 'N: Name="Nintendo Switch Combined Joy-Cons"' ]] && return 0
    done < /proc/bus/input/devices

    return 1
  }

  render_status() {
    local left_connected=false
    local right_connected=false

    [[ -n $LEFT_PATH ]] && is_connected "$LEFT_PATH" && left_connected=true
    [[ -n $RIGHT_PATH ]] && is_connected "$RIGHT_PATH" && right_connected=true

    if has_combined_gamepad; then
      printf ' combined\ncombined\n%s\n' '${colors.green}'
    elif [[ $left_connected == true && $right_connected == true ]]; then
      printf ' pair\npair\n%s\n' '${colors.yellow}'
    elif [[ $left_connected == true || $right_connected == true ]]; then
      printf ' 1/2\n1/2\n%s\n' '${colors.red}'
    else
      printf ' off\noff\n%s\n' '${colors.foreground}'
    fi
  }

  LEFT_PATH=$(find_device_path "Joy-Con (L)" || true)
  RIGHT_PATH=$(find_device_path "Joy-Con (R)" || true)

  if [[ -v BLOCK_BUTTON ]]; then
    case $BLOCK_BUTTON in
      1) connect_joycons ;;
      3) disconnect_joycons ;;
    esac
  fi

  render_status
''
