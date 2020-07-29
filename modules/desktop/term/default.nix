{ config, options, lib, pkgs, ... }:
with lib;
{
  imports = [
    ./st.nix
    ./termite.nix
  ];

  options.modules.desktop.term = {
    default = mkOption {
      type = types.str;
      default = "termite";
    };
  };

  config = {
    services.xserver.desktopManager.xterm.enable = false;

    my.env.TERMINAL = config.modules.desktop.term.default;
  };
}
