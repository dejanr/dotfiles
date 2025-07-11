{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.home.cli.git;

in {
  options.modules.home.cli.git = { enable = mkEnableOption "git"; };
  config = mkIf cfg.enable {
    programs.git = {
      enable = true;
      delta.enable = true;
      delta.options = {
        dark = true;
        features = "unobtrusive-line-numbers decorations";
        side-by-side = true;
        line-numbers-left-format = "";
        line-numbers-right-format = "│ ";
      };
      lfs.enable = true;
      userName = "Dejan Ranisavljevic";
      userEmail = "dejan@ranisavljevic.com";
      extraConfig = {
        init = { defaultBranch = "main"; };
        submodule = { recurse = true; };
        github = { user = "dejanr"; };
        "filter \"lfs\"" = {
          clean = "${pkgs.git-lfs}/bin/git-lfs clean -- %f";
          smudge = "${pkgs.git-lfs}/bin/git-lfs smudge --skip -- %f";
          process = "${pkgs.git-lfs}/bin/git-lfs filter-process --skip";
          required = true;
        };
      };

      includes = [
        {
          condition = "gitdir:~/projects/futurice/";
          contents = {
            user = {
              email = "dejan.ranisavljevic@futurice.com";
              name = "Dejan Ranisavljevic";
            };
          };
        }
        {
          condition = "gitdir:~/projects/ororatech/";
          contents = {
            user = {
              email = "dejan.ranisavljevic@ororatech.com";
              name = "Dejan Ranisavljevic";
            };
          };
        }
      ];
    };
    programs.lazygit = {
      enable = true;
      settings = {
        git.paging.colorArg = "always";
        git.paging.pager = "delta --dark --paging=never";
      };
    };
  };
}
