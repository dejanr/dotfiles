{ ... }:
{
  autoGroups = {
    dejanr = { };
  };

  autoCommands = [
    # Nix files use 4 space indentation
    {
      event = "FileType";
      pattern = "nix";
      command = "setlocal shiftwidth=4";
    }

    # Reload files from disk when we focus vim
    {
      event = "FocusGained";
      pattern = "*";
      command = "if getcmdwintype() == '' | checktime | endif";
      group = "dejanr";
    }

    # Every time we enter an unmodified buffer, check if it changed on disk
    {
      event = "BufEnter";
      pattern = "*";
      command = "if &buftype == '' && !&modified && expand('%') != '' | exec 'checktime ' . expand('<abuf>') | endif";
      group = "dejanr";
    }
  ];
}
