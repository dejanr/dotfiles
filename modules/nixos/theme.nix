{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.nixos.theme;
in
{
  options.modules.nixos.theme = {
    enable = lib.mkEnableOption "Enable theme settings";
    flavor = lib.mkOption {
      type = lib.types.str;
      default = "mocha";
    };
  };

  config = mkIf cfg.enable {
    catppuccin.enable = true;
    catppuccin.flavor = config.modules.nixos.theme.flavor;
  };
}
