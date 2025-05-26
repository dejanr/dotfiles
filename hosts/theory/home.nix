{ config, lib, inputs, pkgs, ... }:

{
  imports = [ ../../modules/default.nix ];

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
    defaultApplications."x-scheme-handler/http" =
      [ "chromium.desktop" ];
    defaultApplications."x-scheme-handler/https" =
      [ "chromium.desktop" ];
    defaultApplications."text/html" = [ "chromium.desktop" ];
    defaultApplications."x-scheme-handler/about" =
      [ "chromium.desktop" ];
    defaultApplications."x-scheme-handler/unknown" =
      [ "chromium.desktop" ];
  };

  config.modules = {
    # gui
    kitty.enable = true;
    kitty.fontSize = "14.0";

    # cli
    direnv.enable = true;
    git.enable = true;
    nvim.enable = true;
    tmux.enable = true;
    zsh.enable = true;

    # graphical
    hyprland.enable = true;

    # system
    packages.enable = true;
  };
}
