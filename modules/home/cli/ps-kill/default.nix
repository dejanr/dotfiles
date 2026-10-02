{ pkgs }:

pkgs.writeShellApplication {
  name = "ps-kill";
  runtimeInputs =
    with pkgs;
    [
      coreutils
      fzf
      gawk
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.procps ];
  text = builtins.readFile ./ps-kill.sh;
}
