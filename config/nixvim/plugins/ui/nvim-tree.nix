{ pkgs, ... }:
{
  plugins.nvim-tree = {
    enable = true;
  };

  extraPlugins = with pkgs.vimPlugins; [
    {
      plugin = circles-nvim;
      config = ''
        lua << EOF
          local circles = require('circles')

          circles.setup({
            icons = { empty = '◯', filled = '●', lsp_prefix = '●' },
            lsp = true
          })

          require('nvim-tree').setup {
            renderer = {
              icons = {
                glyphs = circles.get_nvimtree_glyphs(),
                show = {
                  file = true,
                  folder = true,
                  folder_arrow = false,
                  git = false
                }
              },
            },
          }
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
