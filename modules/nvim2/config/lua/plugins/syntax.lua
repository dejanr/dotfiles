return {
  -- Universal language parser
  {
    "nvim-treesitter/nvim-treesitter",
    event = "BufRead",
    dependencies = {
      { "nvim-treesitter/nvim-treesitter-textobjects" },
    },
    keys = {
      { "<leader>T", ":Inspect<CR>", desc = "Show highlighting groups and captures" },
    },
    config = function()
      if vim.gcc_bin_path ~= nil then
        require("nvim-treesitter.install").compilers = { vim.g.gcc_bin_path }
      end

      ---@diagnostic disable-next-line: missing-fields
      require("nvim-treesitter.configs").setup {
        auto_install = true,
        autopairs = {
          enable = true,
        },
        ensure_installed = {
          "bash",
          "csv",
          "go",
          "graphql",
          "html",
          "javascript",
          "json",
          "latex",
          "lua",
          "gleam",
          "markdown",
          "markdown_inline",
          "nix",
          "python",
          "terraform",
          "toml",
          "org",
          "regex",
          "rust",
          "vim",
          "vimdoc",
          "tsx",
          "typescript",
          "xml",
          "yaml",
        },
        indent = { enable = true },
        matchup = { enable = true },
        playground = { enable = true },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            node_incremental = "v",
            node_decremental = "V",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = { query = "@function.outer", desc = "outer function" },
              ["if"] = { query = "@function.inner", desc = "inner function" },
              ["ac"] = { query = "@class.outer", desc = "outer class" },
              ["ic"] = { query = "@class.inner", desc = "inner class" },
              ["an"] = { query = "@parameter.outer", desc = "outer parameter" },
              ["in"] = { query = "@parameter.inner", desc = "inner parameter" },
            },
          },
          swap = { enable = true },
        },
        query_linter = {
          enable = true,
          use_virtual_text = true,
          lint_events = { "BufWrite", "CursorHold" },
        },
      }
    end,
  },
  -- Show sticky context for off-screen scope beginnings
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = "VeryLazy",
    opts = {
      enable = true,
      max_lines = 5,
      trim_scope = "outer",
      zindex = 40,
      mode = "cursor",
      separator = nil,
    },
  },
  -- Playground treesitter utility
  {
    "nvim-treesitter/playground",
    cmd = "TSPlaygroundToggle",
  },
  {
    "calops/hmts.nvim",
    enabled = false,
    dev = false,
  },
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    event = "VeryLazy",
    opts = {
      signs = false,
    },
  },
}
