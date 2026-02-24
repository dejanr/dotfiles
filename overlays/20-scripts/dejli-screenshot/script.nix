{ pkgs }:

let
  grim = "${pkgs.grim}/bin/grim";
  slurp = "${pkgs.slurp}/bin/slurp";
  wlCopy = "${pkgs.wl-clipboard}/bin/wl-copy";
  slop = "${pkgs.slop}/bin/slop";
  shotgun = "${pkgs.shotgun}/bin/shotgun";
  xclip = "${pkgs.xclip}/bin/xclip";
in
# bash
''
  #!/usr/bin/env bash

  set -euo pipefail

  OUTPUT_DIR="$HOME/archive/dejli-screenshots"
  OUTPUT_FILE="$OUTPUT_DIR/$(date +%Y%m%d_%H%M%S).png"

  mkdir -p "$OUTPUT_DIR"

  if [[ "''${XDG_SESSION_TYPE:-}" == "wayland" || -n "''${WAYLAND_DISPLAY:-}" ]]; then
    SELECTION=$(${slurp}) || exit 0
    [[ -n "$SELECTION" ]] || exit 0

    ${grim} -g "$SELECTION" - | tee "$OUTPUT_FILE" | ${wlCopy} --type image/png >/dev/null
  else
    SELECTION=$(${slop}) || exit 0
    [[ -n "$SELECTION" ]] || exit 0

    ${shotgun} -f png -g "$SELECTION" - | tee "$OUTPUT_FILE" | ${xclip} -t image/png -selection clipboard >/dev/null
  fi
''
