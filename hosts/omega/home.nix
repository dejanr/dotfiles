{ pkgs, ... }:

{
  imports = [ ../../modules/default.nix ];

  # TODO: move this, reorganize
  config.home.file."npmrc".text = ''
    prefix = ~/.npm-packages
  '';
  config.home.file."npmrc".target = ".npmrc";

  config.xdg.mimeApps = {
    defaultApplications."x-scheme-handler/http" =
      [ "google-chrome-stable.desktop" ];
    defaultApplications."x-scheme-handler/https" =
      [ "google-chrome-stable.desktop" ];
    defaultApplications."text/html" = [ "google-chrome-stable.desktop" ];
    defaultApplications."x-scheme-handler/about" =
      [ "google-chrome-stable.desktop" ];
    defaultApplications."x-scheme-handler/unknown" =
      [ "google-chrome-stable.desktop" ];
  };

  config.xdg.desktopEntries.eve-online = {
    name = "Eve";
    exec = "env WINEPREFIX=/home/dejanr/games/eve-online WINEARCH=win64 wine64 /home/dejanr/games/eve-online/drive_c/users/dejanr/AppData/Local/eve-online/eve-online.exe";
    icon = "wine";
    terminal = false;
    categories = [ "Game" ];
  };

  config.xdg.desktopEntries.workspace-eve = {
    name = "Workspace For Eve";
    exec = "${pkgs.wm-workspace}/bin/wm-workspace \"6: \" \"GeLaTe\" \"Hachi\" \"Vorah\"";
    icon = "utilities-terminal";
    terminal = true;
    categories = [ "Utility" ];
  };

  config.xdg.desktopEntries.rift = {
    name = "Rift";
    exec = "${pkgs.steam-run}/bin/steam-run ${pkgs.rift}/usr/lib/nohus/rift/bin/rift";
    icon = "utilities-terminal";
    categories = [ "Utility" ];
  };

  config.modules = {
    #common
    xdg.enable = true;

    # secrets
    agenix.enable = true;

    # gui
    kitty.enable = true;

    # cli
    direnv.enable = true;
    git.enable = true;
    nvim.enable = true;
    tmux.enable = true;
    zsh.enable = true;
    yazi.enable = true;
    opencode.enable = true;

    # system
    packages.enable = true;
  };
}
