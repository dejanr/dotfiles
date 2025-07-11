return {
  'nvim-tree/nvim-tree.lua',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'projekt0n/circles.nvim',
  },
  config = function()
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
  end,
}
