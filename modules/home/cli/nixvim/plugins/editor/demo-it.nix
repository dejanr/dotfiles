{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  demoItPluginFromInput = lib.attrByPath [ "demo-it" "packages" system "demo-it-nvim" ] null inputs;
  demoItPlugin =
    if demoItPluginFromInput != null then
      demoItPluginFromInput
    else
      throw "inputs.demo-it.packages.${system}.demo-it-nvim is missing; expose demo-it-nvim from the demo-it flake";
in
{
  extraPlugins = [ demoItPlugin ];

  extraConfigLua = ''
    local socket = vim.env.DEMO_IT_SOCKET
    if socket == nil or socket == "" then
      local home = vim.env.HOME or ""
      if home ~= "" then
        socket = home .. "/.local/state/demo-it/demo-it.sock"
      end
    end

    require("demo-it").setup({
      socket = socket,
    })
  '';

  keymaps = [
    {
      mode = "n";
      key = "<leader>ds";
      action = "<cmd>DemoItStart<cr>";
      options = {
        desc = "demo-it: start";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>dn";
      action = "<cmd>DemoItNext<cr>";
      options = {
        desc = "demo-it: next";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>dp";
      action = "<cmd>DemoItPrev<cr>";
      options = {
        desc = "demo-it: previous";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>dr";
      action = "<cmd>DemoItRerun<cr>";
      options = {
        desc = "demo-it: rerun";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>dt";
      action = "<cmd>DemoItPresentationToggle<cr>";
      options = {
        desc = "demo-it: toggle presentation mode";
        silent = true;
      };
    }
  ];
}
