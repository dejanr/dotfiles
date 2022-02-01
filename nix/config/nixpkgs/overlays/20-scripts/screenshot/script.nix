{ pkgs }:

''
  selection=$(${pkgs.hacksaw} -f "-i %i -g %g")
  ${pkgs.shotgun} $selection - | xclip -t 'image/png' -selection clipboard
''
