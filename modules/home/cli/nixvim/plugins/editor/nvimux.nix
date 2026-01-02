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
          require("nvimux").run(" run-last-history-in-vimux")
        end
      '';
      options = {
        desc = "Run new tmux command";
        silent = true;
      };
    }
  ];
}
