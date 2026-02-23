{ pkgs, ... }:
{
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      pname = "presenting.nvim";
      version = "2026-02-23";
      src = pkgs.fetchFromGitHub {
        owner = "sotte";
        repo = "presenting.nvim";
        rev = "e78245995a09233e243bf48169b2f00dc76341f7";
        sha256 = "sha256-Q/SNFkMSREVEeDiikdMXQCVxrt3iThQUh08YMcN9qSk=";
      };
    })
  ];

  extraConfigLua = ''
    require("presenting").setup({})
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>P";
      action = "<cmd>Presenting<cr>";
      options = {
        desc = "Toggle Presenting mode";
        silent = true;
      };
    }
  ];
}
