{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.cli.jujutsu;

in
{
  options.modules.home.cli.jujutsu = {
    enable = mkEnableOption "jujutsu";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.jujutsu ];

    programs.jujutsu = {
      enable = true;
      settings = {
        user = {
          name = "Dejan Ranisavljevic";
          email = "dejan@ranisavljevic.com";
        };
        ui = {
          default-command = "log";
          diff-formatter = "delta";
          pager = "delta";
        };
        merge-tools.delta = {
          program = "${pkgs.delta}/bin/delta";
          diff-args = [ "--color-only" ];
        };
        merge-tools.mergiraf = {
          program = "${pkgs.mergiraf}/bin/mergiraf";
          merge-args = [
            "merge"
            "$base"
            "$left"
            "$right"
            "-o"
            "$output"
            "--fast"
          ];
          merge-conflict-exit-codes = [ 1 ];
          conflict-marker-style = "git";
        };
        aliases = {
          l = [
            "log"
            "--no-pager"
            "--limit"
            "10"
          ];
          s = [
            "status"
            "--no-pager"
          ];
          d = [ "diff" ];
          n = [ "new" ];
          e = [ "edit" ];
        };
      };
    };
  };
}
