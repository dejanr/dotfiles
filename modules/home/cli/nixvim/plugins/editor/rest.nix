{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    rest-nvim
  ];

  extraConfigLua = ''
    require('rest-nvim').setup({
      result_split_horizontal = false,
      result_split_in_place = false,
      skip_ssl_verification = false,
      encode_url = true,
      highlight = {
        enabled = true,
        timeout = 150,
      },
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>rr";
      action = "<Plug>RestNvim";
      options = {
        desc = "Run HTTP request";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>rp";
      action = "<Plug>RestNvimPreview";
      options = {
        desc = "Preview HTTP request";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>rl";
      action = "<Plug>RestNvimLast";
      options = {
        desc = "Re-run last HTTP request";
        silent = true;
      };
    }
  ];
}
