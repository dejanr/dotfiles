{ pkgs, ... }: {

  gtk.iconTheme = {
    name = "Gruvbox Plus Dark";
    package = pkgs.callPackage ./gruvbox-plus-dark.nix { };
  };

  xdg.desktopEntries = {
    Helix = {
      name = "Helix";
      noDisplay = true;
    };
    nvim = {
      name = "NeoVim";
      noDisplay = true;
    };
    cups = {
      name = "Printing";
      noDisplay = true;
    };
  };
}
