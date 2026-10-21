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
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.procps ];
  text = builtins.readFile ./ps-kill.sh;
}
