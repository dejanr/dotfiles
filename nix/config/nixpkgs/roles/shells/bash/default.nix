{ ... }:

{
  imports = [
    ../common/aliases.nix
  ];

  programs.bash = {
    enableCompletion = true;
  };

  users.users.dejanr.shell = "/run/current-system/sw/bin/bash";
}
