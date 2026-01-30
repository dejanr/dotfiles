{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.gui.grobi;

  grobiConfig = {
    rules = cfg.rules;
  };

  configFile = pkgs.writeText "grobi.conf" (builtins.toJSON grobiConfig);
in
{
  options.modules.home.gui.grobi = {
    enable = mkEnableOption "grobi display manager";

    rules = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "List of grobi rules";
      example = literalExpression ''
        [
          {
            name = "TV";
            outputs_connected = [ "HDMI-1" ];
            configure_single = "HDMI-1";
            primary = "HDMI-1";
            mode = {
              "HDMI-1" = "3840x2160@120";
            };
          }
        ]
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.grobi ];

    xdg.configFile."grobi.conf".text = builtins.toJSON grobiConfig;

    systemd.user.services.grobi = {
      Unit = {
        Description = "Grobi display manager";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        Requisite = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        # Wait for X environment to be imported
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        ExecStart = "${pkgs.grobi}/bin/grobi watch -v";
        Restart = "on-failure";
        RestartSec = 5;
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
