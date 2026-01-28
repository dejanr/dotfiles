{ ... }:
{
  extraConfigLua = ''
    require('dejanr.pi-mono').setup({})
  '';

  keymaps = [
    {
      mode = "v";
      key = "<leader>pp";
      action = ":<C-u>lua require('dejanr.pi-mono').send_selection()<CR>";
      options = {
        desc = "Send to pi-mono";
        silent = true;
      };
    }
  ];
}
