{ config, pkgs, inputs, ... }:

{
  environment.systemPackages = [
    pkgs.star-citizen
    pkgs.wine-ge
    pkgs.appimage-run
    pkgs.dxvk
    pkgs.vkd3d-proton
    pkgs.wineprefix-preparer
    pkgs.winetricks-git

    pkgs.jeveassets
    pkgs.gamemode # Optimise Linux system performance on demand
    pkgs.winetricks
    pkgs.cabextract
    pkgs.gamemode
    pkgs.libstrangle
    pkgs.vulkan-loader
    pkgs.vulkan-validation-layers
    pkgs.vulkan-tools
    pkgs.legendary-gl # A free and open-source Epic Games Launcher alternative
    pkgs.teamspeak_client # voip client
    pkgs.jstest-gtk
    pkgs.linuxConsoleTools

    pkgs.discord-canary
    pkgs.pyfa

    pkgs.mumble # Low-latency, high quality voice chat software

    pkgs.heroic # Native GOG, Epic, and Amazon Games Launcher for Linux, Windows and Mac
    pkgs.mangohud # A Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more
    pkgs.libstrangle # Frame rate limiter for Linux/OpenGL
    pkgs.protonup-qt
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
        extraPkgs = (pkgs: with pkgs; [
          gamemode
        ]);
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
  services.flatpak.enable = true;
}
