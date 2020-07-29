{ config, lib, pkgs, ... }:

with lib;
{
  options.modules.desktop.term.termite = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.desktop.term.termite.enable {
    my.packages = with pkgs; [
      termite
    ];
  };
}
