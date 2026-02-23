{ ... }:
{
  imports = [
    ./colorschemes/catppuccin.nix
    ./ui/lualine.nix
    ./ui/nvim-tree.nix
    ./ui/which-key.nix
    ./ui/zen-mode.nix
    ./ui/presenting.nix
    ./ui/dressing.nix
    ./editor/telescope.nix
    ./editor/treesitter.nix
    ./editor/nvim-autopairs.nix
    ./editor/nvim-surround.nix
    ./editor/diagnostics.nix
    ./editor/rest.nix
    ./editor/glance.nix
    ./editor/grug-far.nix
    ./editor/neoclip.nix
    ./editor/nvimux.nix
    ./editor/mdx.nix
    ./editor/pi-mono.nix
    ./lsp/lspconfig.nix
    ./lsp/conform.nix
    ./completion/blink-cmp.nix
    ./git/git.nix
  ];
}
