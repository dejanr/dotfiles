return {
  'm42e/nvimux',
  keys = {
    { "t", function()
      require("nvimux").run_last()
    end,                        desc = 'Run last command' },
    { "T", function()
      require("nvimux").run(" run-last-history-in-vimux")
    end, desc = 'Run new command' }
  },
  config = function()
    require('nvimux').setup({
      -- the height/width of the pane if it has to be created
      height = '20%',
      -- the orientation, either `h`orizontal or `v`ertical
      orientation = "v",
      -- Use a pane/window near the current one, if existing
      use_nearest = true,
      -- Reset equences based on the mode of the tmux pane
      reset_mode_sequence = {
        -- copy-mode could be left with `q`
        ["copy-mode"] = "q",
      },
      -- The string to ask the user for a command to enter
      prompt_string = "Command? ",
      -- Run in `pane` or `window`
      runner_type = "pane",
      -- Specify a specific pane/window name
      runner_name = "",
      -- Tmux command or full path to be used
      tmux_command = "tmux",
      -- additional arguments for the pane if created
      open_extra_args = {},
      -- Expand commands, entered into the prompt
      expand_command = false,
      -- Close the pane on exit
      close_on_exit = false,
      -- Provide shell command completion for prompt
      command_shell = true,
      -- Find a runner by a specific query, see tmux for possible filters
      runner_query = {},
      -- Key combinations used
      keys = {
        -- for clearing the screen
        clear_screen = "C-l",
        -- for scrolling up in copy-mode
        scroll_up = "C-u",
        -- for scrolling down in copy-mode
        scroll_down = "C-d",
        -- for resetting the commandline (delete current line)
        reset_cmdline = "C-u",
        -- to interrupt runninng command
        interrupt = "C-c",
        -- to confirm command
        confirm_command = "Enter",
      },
    })
  end,
}
