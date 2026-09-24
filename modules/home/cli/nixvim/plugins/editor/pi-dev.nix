{ ... }:
{
  extraConfigLua = ''
    require('dejanr.pi-dev').setup({})
  '';

  keymaps = [
    {
      mode = "v";
      key = "<leader>pp";
      action = ":<C-u>lua require('dejanr.pi-dev').send_selection()<CR>";
      options = {
        desc = "Send to pi-dev";
        silent = true;
      };
    }
  ];
}
