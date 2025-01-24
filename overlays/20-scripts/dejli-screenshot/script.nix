{ pkgs }:

let
  hacksaw = "${pkgs.hacksaw}/bin/hacksaw";
  shotgun = "${pkgs.shotgun}/bin/shotgun";
in
''
  #!/usr/bin/env sh

  OUTPUT_FILE=$(eval echo "~/archive/dejli-screenshots/$(date +%Y%m%d_%H%M%S).png")
  SELECTION=$(${hacksaw} -f "-i %i -g %g")

  mkdir -p $(dirname "$OUTPUT_FILE")

  ${shotgun} $SELECTION - | tee "$OUTPUT_FILE" | xclip -t 'image/png' -selection clipboard
''
