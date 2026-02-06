{ pkgs, ... }:
{
  plugins.nvim-tree = {
    enable = true;
    settings = {
      filesystem_watchers = {
        ignore_dirs = [
          ".direnv"
          ".devenv"
          "node_modules"
          ".git"
        ];
      };
      git.enable = false;
      modified.enable = false;
      diagnostics.enable = false;
      renderer.icons.show = {
        file = true;
        folder = true;
        folder_arrow = false;
        git = false;
        modified = false;
      };
    };
  };

  extraPlugins = with pkgs.vimPlugins; [
    circles-nvim
  ];

  # Setup circles after nvim-tree is configured
  extraConfigLua = ''
    require('circles').setup({
      icons = { empty = '◯', filled = '●', lsp_prefix = '●' },
      lsp = true
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>op";
      action = ":NvimTreeFocus<cr>";
      options = {
        desc = "Open file tree";
        silent = true;
      };
    }
  ];
}
