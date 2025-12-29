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
  ];

  extraPlugins = with pkgs.vimPlugins; [
    advanced-git-search-nvim
  ];
}
