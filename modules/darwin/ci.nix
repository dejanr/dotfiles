{
  config,
  lib,
  ...
}:

let
  inherit (config.modules.ci) binaryCache;
  managedNix = config.nix.enable;
  externalNixSettings = lib.generators.toKeyValue {
    mkKeyValue = lib.generators.mkKeyValueDefault {
      mkValueString =
        value:
        if builtins.isList value then
          lib.concatStringsSep " " value
        else if builtins.isBool value then
          lib.boolToString value
        else
          value;
    } " = ";
  } binaryCache.nixSettings;
in
{
  imports = [ ../ci/options.nix ];

  config = lib.mkMerge [
    (lib.mkIf (binaryCache.enable && managedNix) {
      nix.settings = binaryCache.nixSettings;
    })
    (lib.mkIf (binaryCache.enable && !managedNix) {
      environment.etc."nix/dotfiles-ci.conf".text = externalNixSettings;
    })
  ];
}
