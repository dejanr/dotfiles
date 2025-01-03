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
        ensure_installed = {
          'bash',
          'bibtex',
          'comment',
          'cpp',
          'css',
          'csv',
          'erlang',
          'gleam',
          'graphql',
          'go',
          'html',
          'http',
          'java',
          'javascript',
          'jsdoc',
          'json',
          'json5',
          'latex',
          'lua',
          'markdown',
          'markdown_inline',
          'make',
          'nix',
          'ocaml',
          'org',
          'php',
          'python',
          'query',
          'regex',
          'rust',
          'scss',
          'sql',
          'toml',
          'typescript',
          'tsx',
          'terraform',
          'typst',
          'vim',
          'vimdoc',
          'yaml',
          'xml',
        },
        highlight = {
          enable = true,
          disable = { "" },
          additional_vim_regex_highlighting = true,
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
        refactor = {
          enable = true,
          highlight_definitions = {
            enable = true,
            clear_on_cursor_move = true,
          },
          smart_rename = {
            enable = true,
            keymaps = {
              smart_rename = false,
            }
          }
        },
      }
    end,
  },
}
