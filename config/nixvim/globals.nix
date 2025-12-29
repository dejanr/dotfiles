{ ... }:
{
  globals = {
    mapleader = " ";
    maplocalleader = " ";
  };

  # File type detection
  extraConfigLua = ''
    vim.cmd("filetype plugin indent on")
  '';
}
