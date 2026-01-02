{ pkgs, ... }:
{
  plugins.diffview = {
    enable = true;
  };

  plugins.neogit = {
    enable = true;
    settings = {
      commit_editor = {
        staged_diff_split_kind = "vsplit";
        spell_check = false;
      };
      signs = {
        item = [
          ""
          ""
        ];
        section = [
          ""
          ""
        ];
      };
      disable_commit_confirmation = true;
      integrations = {
        telescope = true;
        diffview = true;
      };
    };
  };

  plugins.lazygit = {
    enable = true;
  };

  keymaps = [
    {
      mode = "n";
      key = "<leader>ng";
      action = "<cmd>Neogit<cr>";
      options = {
        desc = "Neogit";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>lg";
      action = "<cmd>LazyGit<cr>";
      options = {
        desc = "LazyGit";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>gb";
      action = "<cmd>GitBlameToggle<cr>";
      options = {
        desc = "Toggle Git Blame";
        silent = true;
      };
    }
  ];

  extraPlugins = with pkgs.vimPlugins; [
    advanced-git-search-nvim
    git-blame-nvim
  ];

  extraConfigLua = ''
    vim.g.gitblame_enabled = 0
    vim.g.gitblame_message_template = '<author> • <date> • <summary>'
  '';
}
