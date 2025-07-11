{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.home.cli.direnv;

in {
  options.modules.home.cli.direnv = { enable = mkEnableOption "direnv"; };
  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
      config = {
        log_format = "-";
      };
    };
  };
}
