{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.nixos.roles.dev;

in
{
  options.modules.nixos.roles.dev = {
    enable = mkEnableOption "development system integration";
  };

  config = mkIf cfg.enable {
    programs.java = {
      enable = true;
      package = pkgs.jdk11;
    };

    environment.systemPackages = with pkgs; [
      # System-level development tools
      binutils
      gcc
      gdb
      gnumake
      gnum4
      patchelf
    ];
  };
}
