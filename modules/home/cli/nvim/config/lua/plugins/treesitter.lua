return {
  -- ──────────────────────── TREESITTER ─────────────────────
  {
    'nvim-treesitter/nvim-treesitter',
    event = { 'BufReadPre', 'BufNewFile' },
    build = ':TSUpdate',
    dependencies = {
      -- ────────────────────── TS TEXTOBJECTS ───────────────────
      { 'nvim-treesitter/nvim-treesitter-textobjects' },
      -- ─────────────────────── TS TREEHOPPER ───────────────────────
      { 'mfussenegger/nvim-treehopper' },
      -- ──────────────────────── TS CONTEXT ─────────────────────
      {
        'nvim-treesitter/nvim-treesitter-context',
        opts = {},
      },
    },
    config = function()
      local configs = require "nvim-treesitter.configs"

      configs.setup {
        ensure_installed = { "all" },
        sync_install = false,
        auto_install = false,
        ignore_install = { "all" },
        modules = {},
        highlight = {
          enable = true,
        },
        autopairs = {
          enable = true,
        },
        indent = { enable = true, disable = { "" } },
        autotag = {
          enable = true,
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ['af'] = { query = '@function.outer', desc = 'outer function' },
              ['if'] = { query = '@function.inner', desc = 'inner function' },
              ['ac'] = { query = '@conditional.outer', desc = 'outer conditional' },
              ['ic'] = { query = '@conditional.inner', desc = 'inner conditional' },
              ['al'] = { query = '@loop.outer', desc = 'outer loop' },
              ['il'] = { query = '@loop.inner', desc = 'inner loop' },
              ['am'] = { query = '@statement.outer', desc = 'outer statement' },
              ['ix'] = { query = '@comment.outer', desc = 'comment' },
            },
            include_surrounding_whitespace = false,
          },
        },
        textsubjects = {
          enable = true,
          prev_selection = ',',
          keymaps = {
            ['.'] = { 'textsubjects-smart', desc = "Select Containers" },
            [';'] = { 'textsubjects-container-outer', desc = "Select Outside Containers" },
            ['i;'] = { 'textsubjects-container-inner', desc = "Select Inside Containers" },
          },
        },
      }
    end,
  },
}
