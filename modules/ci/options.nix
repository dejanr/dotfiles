{ config, lib, ... }:

let
  inherit (lib) mkEnableOption mkOption types;
  inherit (config.modules.ci) binaryCache;
  cache = types.submodule {
    options = {
      url = mkOption {
        type = types.strMatching "https://[^[:space:]@?#]+";
        example = "https://cache.example.org/personal";
      };
      publicKey = mkOption {
        type = types.strMatching "[A-Za-z0-9_.-]+:[A-Za-z0-9+/]+=*";
        description = "Nix public signing key in name:base64 format.";
      };
      priority = mkOption {
        type = types.ints.unsigned;
        default = 41;
        description = "Substituter priority; lower values are tried first.";
      };
    };
  };
in
{
  options.modules.ci.binaryCache = {
    enable = mkEnableOption "signed Nix caches with build fallback";
    caches = mkOption {
      type = types.listOf cache;
      default = [ ];
    };
    nixSettings = mkOption {
      type = types.attrs;
      readOnly = true;
      internal = true;
      default = {
        extra-substituters = map (c: "${c.url}?priority=${toString c.priority}") binaryCache.caches;
        extra-trusted-public-keys = map (c: c.publicKey) binaryCache.caches;
        fallback = true;
      };
    };
  };

  config.assertions = lib.optionals binaryCache.enable [
    {
      assertion = binaryCache.caches != [ ];
      message = "Set modules.ci.binaryCache.caches to at least one HTTPS cache.";
    }
  ];
}
