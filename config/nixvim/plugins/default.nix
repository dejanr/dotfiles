{ ... }:
{
  imports = [
    ./colorschemes/catppuccin.nix
    ./ui/lualine.nix
    ./ui/nvim-tree.nix
    ./ui/which-key.nix
    ./editor/telescope.nix
    ./editor/treesitter.nix
    ./editor/nvim-autopairs.nix
    ./editor/nvim-surround.nix
    ./editor/diagnostics.nix
    ./lsp/lspconfig.nix
    ./lsp/conform.nix
    ./completion/blink-cmp.nix
    ./git/git.nix
    ./ai/avante.nix
  ];
}
