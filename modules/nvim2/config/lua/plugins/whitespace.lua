return {
  'johnfrankmorgan/whitespace.nvim',
  config = function()
    require("whitespace-nvim").setup {
      highlight = 'DiffDelete',
      ignored_filetypes = { 'TelescopePrompt', 'Trouble', 'help' },
      ignore_terminal = true,
    }
  end,
}
