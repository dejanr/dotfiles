{ pkgs, ... }:
{
  plugins.nvim-tree = {
    enable = true;
    settings = {
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
    {
      plugin = circles-nvim;
      config = ''
        lua << EOF
          require('circles').setup({
            icons = { empty = '◯', filled = '●', lsp_prefix = '●' },
            lsp = true
          })
        EOF
      '';
    }
  ];

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
