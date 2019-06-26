{ xorg }: ''
#!/usr/bin/env bash

MIN_BRIGHTNESS=10

# Left click
if [[ "''${BLOCK_BUTTON}" -eq 1 ]]; then
  xbacklight -inc 5
# Right click
elif [[ "''${BLOCK_BUTTON}" -eq 3 ]]; then
  xbacklight -dec 5
fi

brightness=$(${xorg.xbacklight}/bin/xbacklight -get)

if [[ "''${brightness%.*}" -le 0 ]]; then
  exit
fi

percent=$(echo "scale=0;''${brightness}" | bc -l)
percent=''${percent%.*}

if [[ "''${percent}" -le 0 ]]; then
  exit
fi

echo "''${percent}%"
echo ""

if [[ "''${percent}" -le "''${MIN_BRIGHTNESS}" ]]; then
  exit 33
fi
''
