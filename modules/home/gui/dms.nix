{
  config,
  pkgs,
  lib,
  inputs,
  osConfig ? { },
  ...
}:

let
  cfg = config.modules.home.gui.dms;
  shell = config.programs.dank-material-shell;
  profile = pkgs.linkFarm "desktop-profile" [
    {
      name = "settings.json";
      path = config.xdg.configFile."dms/settings.json".source;
    }
    {
      name = "plugin_settings.json";
      path = config.xdg.configFile."dms/plugin_settings.json".source;
    }
    {
      name = "session-preferences.json";
      path = (pkgs.formats.json { }).generate "session-preferences.json" cfg.sessionPreferences;
    }
  ];
in
{
  imports = [ inputs.dms.homeModules.dank-material-shell ];

  options.modules.home.gui.dms = {
    enable = lib.mkEnableOption "declarative-first DMS desktop preferences";

    sessionPreferences = lib.mkOption {
      type = (pkgs.formats.json { }).type;
      default = { };
      description = "Session preference keys to reset without replacing history or operational state.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = pkgs.writeShellApplication {
        name = "desktop-config";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          exec python3 ${./dms/runtime.py} --profile ${profile} "$@"
        '';
      };
      description = "Commands to prepare, check, and export the desktop profile.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.modules.home.gui.niri.enable;
        message = "The DMS profile requires the Niri home module.";
      }
      {
        assertion =
          !shell.systemd.enable && (osConfig.programs.dank-material-shell.systemd.enable or false);
        message = "The DMS profile requires exactly one NixOS-owned DMS service.";
      }
      {
        assertion = shell.session == { };
        message = "Use sessionPreferences instead of replacing mutable DMS session state.";
      }
    ];

    programs.dank-material-shell = {
      enable = true;
      package =
        osConfig.programs.dank-material-shell.package
          or inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.default;
      quickshell.package = osConfig.programs.dank-material-shell.quickshell.package or pkgs.quickshell;
      systemd.enable = false;
      enableDynamicTheming = false;
      managePluginSettings = true;
      settings = {
        runDmsMatugenTemplates = lib.mkForce false;
        runUserMatugenTemplates = lib.mkForce false;
      };
    };

    xdg.configFile."dms/settings.json".target = "dms/managed/settings.json";
    xdg.configFile."dms/plugin_settings.json".target = "dms/managed/plugin_settings.json";

    home.packages = [ cfg.package ];
  };
}
