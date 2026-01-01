{ pkgs, ... }:
{
  extraPlugins = with pkgs.vimPlugins; [
    grug-far-nvim
  ];

  extraConfigLua = ''
    require('grug-far').setup({
      -- Start in insert mode
      startInInsertMode = true,
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>sr";
      action = "<cmd>GrugFar<cr>";
      options = {
        desc = "Search and Replace";
        silent = true;
      };
    }
    {
      mode = "v";
      key = "<leader>sr";
      action = "<cmd>GrugFar<cr>";
      options = {
        desc = "Search and Replace (selection)";
        silent = true;
      };
    }
  ];
}
