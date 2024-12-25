return {
  'neovim/nvim-lspconfig',
  config = function()
    local lspconfig = require('lspconfig')
    lspconfig.lua_ls.setup {
      settings = {
        Lua = {
          diagnostics = { globals = { 'vim' } },
          telemetry = {
            enable = false
          }
        }
      }
    }
    lspconfig.ts_ls.setup {
      root_dir = lspconfig.util.root_pattern("package.json"),
      single_file_support = false
    }
    lspconfig.gleam.setup {}
  end,
}
