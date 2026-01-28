{ pkgs, ... }:
{
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      pname = "nvimux";
      version = "2024-12-30";
      src = pkgs.fetchFromGitHub {
        owner = "m42e";
        repo = "nvimux";
        rev = "de96d3510c840499af505266f85e12a8a901a289";
        sha256 = "sha256-d0ScKypbvfwesRb4zwh3upPKfgNNzrgE99wiILjTROk=";
      };
    })
  ];

  extraConfigLua = ''
    require('nvimux').setup({
      height = '20%',
      orientation = "v",
      use_nearest = true,
      reset_mode_sequence = {
        ["copy-mode"] = "q",
      },
      prompt_string = "Command? ",
      runner_type = "pane",
      runner_name = "",
      tmux_command = "tmux",
      open_extra_args = {},
      expand_command = false,
      close_on_exit = false,
      command_shell = true,
      runner_query = {},
      keys = {
        clear_screen = "C-l",
        scroll_up = "C-u",
        scroll_down = "C-d",
        reset_cmdline = "C-u",
        interrupt = "C-c",
        confirm_command = "Enter",
      },
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "t";
      action.__raw = ''
        function()
          require("nvimux").run_last()
        end
      '';
      options = {
        desc = "Run last tmux command";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "T";
      action.__raw = ''
        function()
          -- Find last clear; command from zsh history and run it via nvimux
          local handle = io.popen("fc -ln -1000 2>/dev/null | grep 'clear\\;' | tail -1")
          if not handle then
            vim.notify("Could not read history", vim.log.levels.ERROR)
            return
          end

          local cmd = handle:read("*a")
          handle:close()
          cmd = cmd:gsub("^%s+", ""):gsub("%s+$", "")

          if cmd == "" then
            vim.notify("No 'clear;' command found in history", vim.log.levels.WARN)
            return
          end

          require("nvimux").run(cmd)
        end
      '';
      options = {
        desc = "Run last clear; command from shell history";
        silent = true;
      };
    }
  ];
}
