return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  lazy = false,
  opts = {
    -- UI configuration
    ui = {
      border = "rounded",
      width = 0.8,
      height = 0.8,
    },
    -- Key mappings
    keys = {
      submit = "<C-CR>",
      interrupt = "<C-c>",
      ask = "<leader>aa",     -- ask
      edit = "<leader>ae",    -- edit
      refresh = "<leader>ar", -- refresh
      new_chat = "<leader>an",
    },
    cursor_applying_provider = nil, -- The provider used in the applying phase of Cursor Planning Mode, defaults to nil, when nil uses Config.provider as the provider for the applying phase
    auto_suggestions_provider = "claude",
    provider = "claude",
    claude = {
      endpoint = "https://api.anthropic.com",
      model = "claude-3-7-sonnet-latest",
      temperature = 0,
      max_tokens = 8192,
    },
    -- Error handling
    on_error = function(err)
      vim.notify("Avante Error: " .. err, vim.log.levels.ERROR)
    end,
  },
  build = "make",
  dependencies = {
    -- Core dependencies
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",

    -- Completion
    "hrsh7th/nvim-cmp",

    -- Icons
    "echasnovski/mini.icons",

    -- Image handling
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      },
    },

    -- Markdown rendering
    {
      'MeanderingProgrammer/render-markdown.nvim',
      opts = {
        file_types = { "markdown", "Avante" },
        renderer_options = {
          highlight = {
            enable = true,
          },
        },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
