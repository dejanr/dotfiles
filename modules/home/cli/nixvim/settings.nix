{ ... }:
{
  opts = {
    # Performance
    shell = "zsh";
    shadafile = "NONE";

    # Colors
    termguicolors = true;

    # Undo files
    undofile = true;

    # Indentation
    tabstop = 2;
    shiftwidth = 2;
    softtabstop = 2;
    shiftround = true;
    expandtab = true;
    autoindent = true;
    smartindent = true;
    scrolloff = 8; # Keep cursor 8 lines from top/bottom when scrolling

    # Set clipboard to use system clipboard
    clipboard = "unnamedplus";

    # Use mouse
    mouse = "a";

    # Nicer UI settings
    cursorline = true;
    number = true;

    # Get rid of annoying viminfo file
    viminfo = "";
    viminfofile = "NONE";

    # Miscellaneous quality of life
    ignorecase = true;
    ttimeoutlen = 5;
    hidden = true;
    shortmess = "atI";
    wrap = false;
    backup = false;
    writebackup = false;
    errorbells = false;
    swapfile = false;
    showmode = false;
    laststatus = 3;
    pumheight = 6;
    splitright = true;
    splitbelow = true;
    completeopt = "menuone,noselect";

    # Display sign column always fixed by up to 1 sign
    signcolumn = "yes:1";

    # Auto reload files changed outside of vim
    autoread = true;

    # Enable project-local .nvim.lua files (requires :trust per project)
    exrc = true;
  };
}
