{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

{
  imports = [ ../../modules/home/default.nix ];

  config.programs.chromium = {
    enable = true;
    extensions = [
      "aeblfdkhhhdcdjpifhhbdiojplfjncoa" # 1Password – Password Manager
      "gighmmpiobklfepjocnamgkkbiglidom" # AdBlock
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # UBlock Origin
      "aapbdbdomjkkjkaonfhkkikfgjllcleb" # Google Translate
      "fmkadmapgofadopljbjfkapdkoienihi" # React Developer Tools
      "okpjlejfhacmgjkmknjhadmkdbcldfcb" # User CSS Override
      "nmgcefdhjpjefhgcpocffdlibknajbmj" # MyMind
    ];
  };

  config.xdg.mimeApps = {
    defaultApplications."x-scheme-handler/http" = [ "chromium.desktop" ];
    defaultApplications."x-scheme-handler/https" = [ "chromium.desktop" ];
    defaultApplications."text/html" = [ "chromium.desktop" ];
    defaultApplications."x-scheme-handler/about" = [ "chromium.desktop" ];
    defaultApplications."x-scheme-handler/unknown" = [ "chromium.desktop" ];
  };

  config.modules = {
    # gui
    home.gui.desktop.enable = true;

    # apps
    apps.kitty.enable = true;
    apps.kitty.fontSize = "14.0";

    # cli
    home.cli.direnv.enable = true;
    home.cli.git.enable = true;
    home.cli.nixvim.enable = true;
    home.cli.tmux.enable = true;
    home.cli.zsh.enable = true;

    # graphical
    home.gui.hyprland.enable = true;

    # system
    home.common.packages.enable = true;
  };
}
