{ pkgs, ... }:
{
  plugins.treesitter = {
    enable = true;

    settings = {
      highlight = {
        enable = true;
      };

      indent = {
        enable = true;
      };

      incremental_selection = {
        enable = true;
      };
    };

    nixGrammars = true;
    grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
  };

  plugins.treesitter-context = {
    enable = true;
  };

  plugins.treesitter-textobjects = {
    enable = true;

    select = {
      enable = true;
      lookahead = true;

      keymaps = {
        "af" = "@function.outer";
        "if" = "@function.inner";
        "ac" = "@conditional.outer";
        "ic" = "@conditional.inner";
        "al" = "@loop.outer";
        "il" = "@loop.inner";
        "am" = "@statement.outer";
        "ix" = "@comment.outer";
      };
    };
  };

  plugins.ts-autotag = {
    enable = true;
  };
}
