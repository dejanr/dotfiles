{ libnotify, maim, xclip }:

''
#!/usr/bin/env bash

# Left click
if [[ "''${BLOCK_BUTTON}" -eq 1 ]]; then
  DIR=$HOME/pictures/screenshots
  FILE="$DIR/$(date +%s).png"
  mkdir -p $DIR

  ${maim}/bin/main -s $FILE
  ${xclip}/bin/xclip -se c -t image/png -in $FILE
  ${libnotify}/bin/notify-send Screenshot "Saved to clipboard"
fi

echo ""
echo ""

exit 0
''
