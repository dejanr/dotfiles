{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.cli.vim;

in
{
  options.modules.home.cli.vim = {
    enable = mkEnableOption "vim";
  };
  config = mkIf cfg.enable {
    # vim
  };
}
