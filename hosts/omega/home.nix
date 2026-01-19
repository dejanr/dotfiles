{ pkgs, ... }:

{
  imports = [ ../../modules/home/default.nix ];

  # TODO: move this, reorganize
  config.home.file."npmrc".text = ''
    prefix = ~/.npm-packages
  '';
  config.home.file."npmrc".target = ".npmrc";

  config.home.packages = with pkgs; [
    slack
  ];

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

  config.xdg.desktopEntries.darkfall-roa = {
    name = "Darkfall: Rise of Agon";
    exec = "${pkgs.writeShellScript "darkfall-roa" ''
      export WINEPREFIX="/home/dejanr/games/riseofagon"
      export WINEARCH=win32
      cd "/home/dejanr/games/riseofagon/drive_c/Program Files/Darkfall RoA"
      wine ./Darkfall_RoA.exe
    ''}";
    icon = "wine";
    terminal = false;
    categories = [ "Game" ];
  };

  config.modules = {
    home.common.packages.enable = true;

    # secrets
    home.secrets.agenix.enable = true;

    # gui
    home.gui.xdg.enable = true;
    home.gui.desktop.enable = true;
    home.gui.games.enable = true;
    home.gui.browser.qutebrowser.enable = true;

    # apps
    apps.kitty.enable = true;
    apps.ghostty.enable = true;

    # cli
    home.cli.direnv.enable = true;
    home.cli.git.enable = true;
    home.cli.jujutsu.enable = true;
    home.cli.dev.enable = true;
    home.cli.nixvim.enable = true;
    home.cli.tmux.enable = true;
    home.cli.zsh.enable = true;
    home.cli.yazi.enable = true;
    home.cli.opencode.enable = true;
    home.cli.pi-mono.enable = true;
  };

  config.home.stylix.theme = "catppuccin-mocha";
}
