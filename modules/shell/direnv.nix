{ config, options, lib, pkgs, ... }:

with lib; {
  options.modules.shell.direnv = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
  };

  config = mkIf config.modules.shell.direnv.enable {
    my = { packages = [ pkgs.direnv ]; };

    services.lorri.enable = true;
  };
}
