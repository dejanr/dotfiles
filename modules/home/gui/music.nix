{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.modules.home.gui.music;
  useCredentials = cfg.credentialsSecret != null;
  feishin =
    if useCredentials then
      pkgs.feishin.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./music/credentials.patch ];
      })
    else
      pkgs.feishin;

  launcher = pkgs.writeShellScriptBin "music" ''
    export SERVER_NAME=Synology
    export SERVER_TYPE=navidrome
    export SERVER_URL=${escapeShellArg cfg.serverUrl}
    ${optionalString useCredentials ''
      export SERVER_CREDENTIALS_FILE="${config.age.secrets.navidrome_credentials.path}"
      export SERVER_LOCK=true
      if [ ! -r "$SERVER_CREDENTIALS_FILE" ]; then
        printf 'Navidrome credentials are not readable; activate Home Manager/agenix first.\n' >&2
        exit 1
      fi
    ''}
    exec ${feishin}/bin/feishin "$@"
  '';
in
{
  options.modules.home.gui.music = {
    enable = mkEnableOption "Synology music with Feishin";

    serverUrl = mkOption {
      type = types.str;
      default = "http://100.69.35.105:4533";
      description = "Navidrome URL prefilled in the music launcher.";
    };

    credentialsSecret = mkOption {
      type = types.nullOr types.path;
      default = ../../../secrets/navidrome_credentials.age;
      example = literalExpression "../../secrets/navidrome_credentials.age";
      description = ''
        Encrypted agenix JSON file containing username and password strings.
        Decrypted at runtime and used to prefill Feishin's Add Server form.
        The server is locked to serverUrl when credentials are configured.
      '';
    };

    musicDirectory = mkOption {
      type = types.strMatching "/.+";
      default = "${config.home.homeDirectory}/documents/music";
      description = "Local music and file-playlist directory, shared bidirectionally through Syncthing.";
    };

    sync = {
      enable = mkEnableOption "bidirectional Syncthing for music";

      device = mkOption {
        type = types.str;
        default = "synology";
        description = "Existing services.syncthing.settings.devices peer to share the folders with.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !useCredentials || config.modules.home.secrets.agenix.enable;
        message = "Feishin credentialsSecret requires modules.home.secrets.agenix.enable.";
      }
      {
        assertion =
          !cfg.sync.enable
          || (
            config.services.syncthing.enable
            && hasAttr cfg.sync.device config.services.syncthing.settings.devices
          );
        message = "Music sync requires Syncthing enabled and sync.device declared as a peer.";
      }
    ];

    home.packages = [
      feishin
      launcher
    ];

    age.secrets.navidrome_credentials = mkIf useCredentials {
      file = cfg.credentialsSecret;
    };

    xdg.desktopEntries.feishin = mkIf pkgs.stdenv.hostPlatform.isLinux {
      name = "Feishin";
      comment = "Synology music";
      exec = "${launcher}/bin/music %u";
      icon = "feishin";
      terminal = false;
      categories = [
        "Audio"
        "AudioVideo"
        "Player"
        "Music"
      ];
      mimeType = [ "x-scheme-handler/feishin" ];
    };

    services.syncthing.settings.folders = mkIf cfg.sync.enable {
      music = {
        id = "music";
        label = "Music";
        path = cfg.musicDirectory;
        type = "sendreceive";
        devices = [ cfg.sync.device ];
        ignorePerms = true;
      };
    };
  };
}
