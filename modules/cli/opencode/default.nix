{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.opencode;
in
{
  options.modules.opencode = {
    enable = mkEnableOption "opencode";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      opencode
    ];

    programs.opencode = {
      enable = true;

      settings = {
        theme = "nord";
        model = "anthropic/claude-sonnet-4-20250514";
        autoshare = false;
        autoupdate = false;
      };
    };
  };
}

