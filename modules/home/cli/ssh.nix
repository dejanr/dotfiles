{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.home.cli.ssh;
in
{
  options.modules.home.cli.ssh = {
    enable = lib.mkEnableOption "SSH client configuration";
  };

  config = lib.mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          AddKeysToAgent = "yes";
          LogLevel = "QUIET";
          VisualHostKey = true;
          ServerAliveInterval = 60;
          ServerAliveCountMax = 2;
          SendEnv = [
            "LANG"
            "LC_*"
          ];
          SetEnv.TERM = "xterm-256color";
        };
        "github github.com" = {
          HostName = "github.com";
          User = "git";
          IdentityFile = "~/.ssh/id_ed25519";
          IdentitiesOnly = true;
        };
      };
    };
  };
}
