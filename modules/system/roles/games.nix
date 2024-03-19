{ config, pkgs, inputs, ... }:

{
  environment.systemPackages = [
    pkgs.appimage-run
    inputs.nix-gaming.packages.${pkgs.system}.wine-tkg
    inputs.nix-gaming.packages.${pkgs.system}.dxvk
    inputs.nix-gaming.packages.${pkgs.system}.vkd3d-proton
    inputs.nix-gaming.packages.${pkgs.system}.wineprefix-preparer

    pkgs.entropia
    pkgs.jeveassets

    pkgs.gamemode # Optimise Linux system performance on demand
    pkgs.mangohud # A Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more
    # pkgs.wine # overlay wine
    pkgs.winetricks
    pkgs.cabextract
    #protontricks
    #pyfa
    pkgs.gamemode
    pkgs.libstrangle
    pkgs.vulkan-loader
    pkgs.vulkan-validation-layers
    pkgs.vulkan-tools
    pkgs.legendary-gl # A free and open-source Epic Games Launcher alternative
    pkgs.teamspeak_client # voip client
    #cemu
    pkgs.jstest-gtk
    pkgs.linuxConsoleTools

    pkgs.discord-canary
  ];

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.dedicatedServer.openFirewall = true;

  services.joycond.enable = true;
}
