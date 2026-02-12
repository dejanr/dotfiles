{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.cli.git;

in
{
  options.modules.home.cli.git = {
    enable = mkEnableOption "git";
  };
  config = mkIf cfg.enable {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        dark = true;
        features = "unobtrusive-line-numbers decorations";
        side-by-side = true;
        line-numbers-left-format = "";
        line-numbers-right-format = "│ ";
      };
    };
    programs.git = {
      enable = true;
      lfs.enable = true;
      settings = {
        user = {
          name = "Dejan Ranisavljevic";
          email = "dejan@ranisavljevic.com";
        };
        pull = {
          rebase = true;
        };
        init = {
          defaultBranch = "main";
        };
        submodule = {
          recurse = true;
        };
        github = {
          user = "dejanr";
        };
        "url \"git@github.com:\"" = {
          insteadOf = "https://github.com/";
        };
        "filter \"lfs\"" = {
          clean = "${pkgs.git-lfs}/bin/git-lfs clean -- %f";
          smudge = "${pkgs.git-lfs}/bin/git-lfs smudge --skip -- %f";
          process = "${pkgs.git-lfs}/bin/git-lfs filter-process --skip";
          required = true;
        };
        "merge \"mergiraf\"" = {
          name = "mergiraf";
          driver = "${pkgs.mergiraf}/bin/mergiraf merge --git %O %A %B -s %S -x %X -y %Y -p %P";
        };
      };
      attributes = [
        "*.java merge=mergiraf"
        "*.rs merge=mergiraf"
        "*.go merge=mergiraf"
        "*.js merge=mergiraf"
        "*.jsx merge=mergiraf"
        "*.json merge=mergiraf"
        "*.yml merge=mergiraf"
        "*.yaml merge=mergiraf"
        "*.toml merge=mergiraf"
        "*.html merge=mergiraf"
        "*.htm merge=mergiraf"
        "*.xhtml merge=mergiraf"
        "*.xml merge=mergiraf"
        "*.c merge=mergiraf"
        "*.cc merge=mergiraf"
        "*.h merge=mergiraf"
        "*.cpp merge=mergiraf"
        "*.hpp merge=mergiraf"
        "*.cs merge=mergiraf"
        "*.dart merge=mergiraf"
        "*.scala merge=mergiraf"
        "*.sbt merge=mergiraf"
        "*.ts merge=mergiraf"
        "*.py merge=mergiraf"
      ];

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
        git.pagers = [
          {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          }
        ];
      };
    };
  };
}
