{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.home.cli.opencode;
in
{
  options.modules.home.cli.opencode = {
    enable = mkEnableOption "opencode";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      opencode
    ];

    home.file.".config/opencode/GUIDELINES.md".text = ''
      # Global Guidelines

      These are global guidelines that you MUST always adhere to.

      - You MUST ONLY add comments if the code you are creating is complex.
      - You MUST ALWAYS perform a deeper research to find existing patterns or integrations of a code against other modules.
      - You MUST ALWAYS prefer a clean and simple functional coding approach.
      - You MUST ALWAYS consider if there is a better approach to a solution compared to the one being asked by the user. Feel free to challenge the user and make suggestions.
      - You MUST NEVER include a test plan in pull requests
    '';

    programs.opencode = {
      enable = true;

      settings = {
        theme = "system";
        model = "anthropic/claude-sonnet-4-20250514";
        autoshare = false;
        autoupdate = false;

        instructions = [ "GUIDELINES.md" "README.md" ];
      };
    };
  };
}

