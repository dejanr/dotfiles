{}: ''
  #!/usr/bin/env bash

  HEADSET_ID=$1

  pushd "$(dirname "$0")" > /dev/null
  popd > /dev/null

  STATUS_CONNECTED="connected"
  STATUS_DISCONNECTED="disconnected"
  ERROR_CONDITION=0

  function show_status() {
  INFO_STRING=$( bluetoothctl <<EOF
  info $HEADSET_ID
  EOF
  )
    STATUS=$(echo "$INFO_STRING" | grep "Connected" | cut -d ":" -f 2 | tr -d '[:space:]')
    [[ "$STATUS" == "yes" ]] && echo $STATUS_CONNECTED && exit 0
    [[ "$STATUS" == "no" ]] && echo $STATUS_DISCONNECTED && exit 0
    echo "Unknown status $STATUS" && exit 1
  }

  function set_profile() {
    IDXS=($(pacmd list-cards | grep 'index' | cut -d ':' -f 2))
    DEVS=($(pacmd list-cards | grep 'device.string' | cut -d '=' -f 2))
    for i in "''${!DEVS[@]}"
    do
      # NOTE the device string returned by pacmd has double-quotes around it
      if [[ "''${DEVS[i]}" == "\"$HEADSET_ID\"" ]]; then
        pacmd set-card-profile "''${IDXS[i]}" "$HEADSET_PROFILE"
        [[ ! $? -eq 0 ]] && echo "Cannot set pulseaudio profile" && ERROR_CONDITION=1 && exit 1
        echo "profile successfully changed"
      fi
    done
  }

  function wait_status() {
    STATUS=$(show_status)
    count=0
    while [[ ! "$STATUS" == "$1" ]]; do
      sleep 1
      STATUS=$(show_status)
      ((count++))
      [[ $count -gt 20 ]] && echo "Timeout waiting for $1 event" && ERROR_CONDITION=1 && exit 1
    done
  }

  function connect() {
  INFO_STRING=$( bluetoothctl <<EOF
  connect $HEADSET_ID
  EOF
  )
    [[ ! $? -eq 0 ]] && exit $?
    wait_status $STATUS_CONNECTED
    set_profile
  }

  function disconnect() {
  INFO_STRING=$( bluetoothctl <<EOF
  disconnect $HEADSET_ID
  EOF
  )
    [[ ! $? -eq 0 ]] && exit $?
    wait_status $STATUS_DISCONNECTED
  }

  STATUS=$(show_status)

  case $BLOCK_BUTTON in
    2)
      if [[ "$STATUS_CONNECTED" == "$STATUS" ]]
      then
        disconnect > /dev/null
        notify-send "Headphones" "Disconnected"
      else
        connect > /dev/null
        notify-send "Headphones" "Connected"
      fi
      ;;
  esac

  if [[ $ERROR_CONDITION -eq 1 ]]
  then
    echo " err"
    echo ""
  elif [[ "$STATUS_CONNECTED" == "$STATUS" ]]
  then
    echo " on"
    echo ""
  else
    echo " off"
    echo ""
  fi

''
