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
  ];
}
