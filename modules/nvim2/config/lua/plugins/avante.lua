return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  opts = {
    provider = "deepseek",
    -- UI configuration
    ui = {
      border = "rounded",
      width = 0.8,
      height = 0.8,
    },
    -- Key mappings
    keys = {
      submit = "<C-s>",
      interrupt = "<C-c>",
      ask = "<leader>aa",     -- ask
      edit = "<leader>ae",    -- edit
      refresh = "<leader>ar", -- refresh
      new_chat = "<leader>an",
    },
    -- Vendor configuration
    vendors = {
      deepseek = {
        __inherited_from = "openai",
        api_key_name = "DEEPSEEK_API_KEY",
        endpoint = "https://api.deepseek.com",
        model = "deepseek-chat",
        -- Add timeout and retry settings
        timeout = 30,
        max_retries = 3,
      },
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
