{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.cli.jira;
in
{
  options.modules.home.cli.jira.enable = lib.mkEnableOption "Jira Cloud access for CTF";

  config = lib.mkIf cfg.enable {
    modules.home.secrets.agenix.enable = true;

    home.packages = [ pkgs.jira-cli-go ];
    age.secrets.jira_env.file = ../../../secrets/jira_env.age;

    home.sessionVariablesExtra = ''
      if [ -r "${config.age.secrets.jira_env.path}" ]; then
        . "${config.age.secrets.jira_env.path}"
      fi
    '';
  };
}
