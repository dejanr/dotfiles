{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.apps.obsidian;
in
{
  options.modules.apps.obsidian = {
    enable = mkEnableOption "obsidian";

    settings = mkOption {
      type = types.attrsOf types.anything;
      default = {
        vaults.main.target = "documents/notes/main";

        defaultSettings.communityPlugins = [
          {
            pkg = pkgs.obsidian-plugin-remarkable-sync;
            settings = {
              subfolder = "reMarkable";
              syncIntervalLabel = "Manual only";
              folderFilter = "";
              lastSyncTime = "";
              isAuthenticated = false;
            };
          }
        ];
      };
      description = "Settings passed through to Home Manager's programs.obsidian module";
      example = literalExpression ''{
        vaults.main.target = "documents/notes/main";
        defaultSettings.communityPlugins = [
          {
            pkg = pkgs.obsidian-plugin-remarkable-sync;
            settings.subfolder = "reMarkable";
          }
        ];
      }'';
    };
  };

  config = mkIf cfg.enable {
    programs.obsidian = {
      enable = true;
    }
    // cfg.settings;
  };
}
