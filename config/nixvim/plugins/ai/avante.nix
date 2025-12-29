{ pkgs, ... }:
{
  plugins.dressing = {
    enable = true;
  };

  plugins.mini = {
    enable = true;
    modules = {
      icons = { };
    };
  };

  extraPlugins = with pkgs.vimPlugins; [
    nui-nvim
    plenary-nvim
    img-clip-nvim
    render-markdown-nvim
  ];

  extraConfigLua = ''
    require('img-clip').setup({
      default = {
        embed_image_as_base64 = false,
        prompt_for_file_name = false,
        drag_and_drop = {
          insert_mode = true,
        },
        use_absolute_path = true,
      },
    })

    require('render-markdown').setup({
      file_types = { "markdown", "Avante" },
      renderer_options = {
        highlight = {
          enable = true,
        },
      },
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>aa";
      action = ":AvanteAsk<cr>";
      options = {
        desc = "Avante Ask";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>ae";
      action = ":AvanteEdit<cr>";
      options = {
        desc = "Avante Edit";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>ar";
      action = ":AvanteRefresh<cr>";
      options = {
        desc = "Avante Refresh";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>an";
      action = ":AvanteNewChat<cr>";
      options = {
        desc = "Avante New Chat";
        silent = true;
      };
    }
  ];
}
