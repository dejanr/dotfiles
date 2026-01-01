{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    nvim-neoclip-lua
  ];

  extraConfigLua = ''
    require('neoclip').setup()
    require('telescope').load_extension('neoclip')
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>fc";
      action = "<cmd>Telescope neoclip<cr>";
      options = {
        desc = "Clipboard History";
        silent = true;
      };
    }
  ];
}
