{ ... }:

{
  programs.bash = {
    enable = true;
    enableCompletion = true;
  };

  users.users.dejanr.shell = "/run/current-system/sw/bin/bash";
}
