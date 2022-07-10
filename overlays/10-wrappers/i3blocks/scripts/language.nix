{}: ''
  #!/usr/bin/env bash

  KB_LAYOUT=$(setxkbmap -query | awk '/layout/{print $2}')

  toggle() {
    if [[ $KB_LAYOUT == "us" ]]; then
      setxkbmap de
    elif [[ $KB_LAYOUT == "de" ]]; then
      setxkbmap rs -variant latin
    elif [[ $KB_LAYOUT == "rs" ]]; then
      setxkbmap us
    fi
  }

  # Left click
  if [[ "''${BLOCK_BUTTON}" -eq 1 ]]; then
    toggle
  fi

  echo " $KB_LAYOUT" | awk '{print toupper($0)}'
  echo ""
''
