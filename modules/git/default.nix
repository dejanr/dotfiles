{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.git;

in {
  options.modules.git = { enable = mkEnableOption "git"; };
  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      lfs.enable = true;
      userName = "dejanr";
      userEmail = "dejan@ranisavljevic.com";
      extraConfig = {
        init = { defaultBranch = "main"; };
        github = { user = "dejanr"; };
  "filter \"lfs\"" = {
     clean = "${pkgs.git-lfs}/bin/git-lfs clean -- %f";
     smudge = "${pkgs.git-lfs}/bin/git-lfs smudge --skip -- %f";
     process = "${pkgs.git-lfs}/bin/git-lfs filter-process --skip";
     required = true;
  };
      };
    };
    programs.lazygit = {
      enable = true;
    };
  };
}
