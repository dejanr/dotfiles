{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.modules.ci) binaryCache attic;
  authority =
    attic.hostname + lib.optionalString (attic.httpsPort != 443) ":${toString attic.httpsPort}";
in
{
  imports = [ ../../ci/options.nix ];

  options.modules.ci.attic = {
    enable = lib.mkEnableOption "an Attic binary cache on loopback";
    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/attic-secrets/server.env";
      description = "Runtime environment file with Attic's token signing secret.";
    };
    hostname = lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9-]+([.][A-Za-z0-9-]+)+";
      example = "omega.example.ts.net";
      description = "The DNS name of the HTTPS reverse proxy, without a scheme or path.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8081;
      description = "Port for the HTTP backend on loopback.";
    };
    httpsPort = lib.mkOption {
      type = lib.types.ints.between 1 65535;
      default = 443;
      description = "HTTPS port advertised to Attic clients and used by the local CI guest relay.";
    };
    retentionDays = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
    };
  };

  config = lib.mkMerge [
    (lib.mkIf binaryCache.enable {
      nix.settings = binaryCache.nixSettings;
    })
    (lib.mkIf attic.enable {
      environment.systemPackages = [ pkgs.attic-client ];
      assertions = [
        {
          assertion =
            lib.hasPrefix "/" attic.environmentFile && !lib.hasPrefix "/nix/store/" attic.environmentFile;
          message = "The Attic environment file must be an absolute runtime path outside the Nix store.";
        }
      ];
      services.atticd = {
        enable = true;
        inherit (attic) environmentFile;
        settings = {
          listen = "127.0.0.1:${toString attic.port}";
          allowed-hosts = lib.unique [
            attic.hostname
            authority
          ];
          api-endpoint = "https://${authority}/";
          require-proof-of-possession = true;
          garbage-collection = {
            interval = "12 hours";
            default-retention-period = "${toString attic.retentionDays} days";
          };
        };
      };
    })
  ];
}
