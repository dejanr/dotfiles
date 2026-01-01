{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    glance-nvim
  ];

  extraConfigLua = ''
    require('glance').setup({
      border = {
        enable = true,
      },
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "gpd";
      action = "<cmd>Glance definitions<cr>";
      options = {
        desc = "Glance Definitions";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "gpr";
      action = "<cmd>Glance references<cr>";
      options = {
        desc = "Glance References";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "gpt";
      action = "<cmd>Glance type_definitions<cr>";
      options = {
        desc = "Glance Type Definitions";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "gpi";
      action = "<cmd>Glance implementations<cr>";
      options = {
        desc = "Glance Implementations";
        silent = true;
      };
    }
  ];
}
