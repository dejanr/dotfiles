{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.system.roles.dev;

in {
  options.modules.system.roles.dev = { enable = mkEnableOption "development system integration"; };

  config = mkIf cfg.enable {
    programs.java = {
      enable = true;
      package = pkgs.jdk11;
    };

    programs.adb.enable = true;

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