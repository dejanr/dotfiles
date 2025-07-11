return {
  'folke/which-key.nvim',
  event = 'VeryLazy',
  enabled = true,
  opts = {
    preset = 'helix',
    expand = 0,
    spec = {
      {
        mode = { 'n', 'v' },
        { '<leader>f', group = '+File' },    -- Telescope
        { '<leader>x', group = '+Trouble' }, -- Trouble.nvim
        { '<leader>g', group = '+Goto' },    -- Trouble.nvim
      },
    },
    win = {
      border = 'single',
      no_overlap = false,
      title_pos = 'center',
    },
    sort = { 'manual', 'group', 'lower' },
  },
}
