{ pkgs }:

let
  hacksaw = "${pkgs.hacksaw}/bin/hacksaw";
  shotgun = "${pkgs.shotgun}/bin/shotgun";
in
''
  #!/usr/bin/env sh

  selection=$(${hacksaw} -f "-i %i -g %g")
  ${shotgun} $selection - | xclip -t 'image/png' -selection clipboard
''
