{ pkgs }:

let
  slop = "${pkgs.slop}/bin/slop";
  shotgun = "${pkgs.shotgun}/bin/shotgun";
in
''
  #!/usr/bin/env sh

  OUTPUT_FILE=$(eval echo "~/archive/dejli-screenshots/$(date +%Y%m%d_%H%M%S).png")
  SELECTION=$(${slop})

  mkdir -p $(dirname "$OUTPUT_FILE")

  ${shotgun} -f png -g $SELECTION - | tee "$OUTPUT_FILE" | xclip -t 'image/png' -selection clipboard
''
