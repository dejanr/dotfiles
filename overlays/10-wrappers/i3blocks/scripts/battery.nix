{ }:
''
  #!/usr/bin/env bash

  BATTERY_STATE=$(battery | grep -wo "Full\|Charging\|Discharging")
  BATTERY_POWER=$(battery | grep -o "[0-9]\+")

  URGENT_VALUE=10

  if [[ $BATTERY_STATE = "Charging" ]]; then
    echo "''${BATTERY_POWER}%+"
    echo ""
  elif [[ $BATTERY_STATE = "Discharging" ]]; then
    echo "''${BATTERY_POWER}%-"
    echo ""
  elif [[ $BATTERY_STATE = "" ]]; then
    echo ""
  else
    echo "''${BATTERY_POWER}%"
    echo ""
  fi
''
