{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.nixos.roles.games;

in
{
  options.modules.nixos.roles.games = {
    enable = mkEnableOption "gaming system integration";
  };

  config = mkIf cfg.enable {
    # System-level gaming packages (Wine, Vulkan drivers, system tools)
    environment.systemPackages = with pkgs; [
      wine-tkg
      wineprefix-preparer
      appimage-run
      winetricks-git
      cabextract
      gamemode
      libstrangle
      vulkan-loader
      vulkan-validation-layers
      vulkan-tools
      jstest-gtk
      linuxConsoleTools
    ];

    programs = {
      steam = {
        enable = true;
        protontricks.enable = true;
        gamescopeSession.enable = true;
        extraPackages = with pkgs; [ libstrangle ];
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
        package = pkgs.steam.override {
          extraPkgs = (
            pkgs: with pkgs; [
              gamemode
            ]
          );
        };
      };
      gamemode = {
        enable = true;
        enableRenice = true;
        settings = {
          general.renice = -20;
        };
      };
      gamescope = {
        enable = true;
        capSysNice = true;
      };
    };

    hardware.steam-hardware.enable = true;
  };
}
