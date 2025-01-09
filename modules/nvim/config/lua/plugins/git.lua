return {
  --  ╭──────────────────────────────────────────────────────────╮
  --  │                         Diffview                         │
  --  ╰──────────────────────────────────────────────────────────╯
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewToggleFiles', 'DiffviewFocusFiles' },
    dependencies = 'nvim-lua/plenary.nvim',
    config = function()
      require('diffview').setup()
    end,
  },
  --  ╭──────────────────────────────────────────────────────────╮
  --  │                          Neogit                          │
  --  ╰──────────────────────────────────────────────────────────╯
  {
    'NeogitOrg/neogit',
    cmd = 'Neogit',
    keys = {
      { '<leader>gg', '<cmd>Neogit<cr>', desc = 'Neogit' },
    },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
      'sindrets/diffview.nvim',
    },
    config = true,
    opts = {
      commit_editor = {
        staged_diff_split_kind = 'vsplit',
        spell_check = false,
      },
      signs = {
        item = { '', '' },
        section = { '', '' },
      },
      disable_commit_confirmation = true,
      integrations = {
        telescope = true,
        diffview = true,
      },
    },
  },
  --  ╭──────────────────────────────────────────────────────────╮
  --  │                    Advance git search                    │
  --  ╰──────────────────────────────────────────────────────────╯
  {
    'aaronhallaert/advanced-git-search.nvim',
    cmd = { 'AdvancedGitSearch' },
    dependencies = {
      'nvim-telescope/telescope.nvim',
    },
  },
}
