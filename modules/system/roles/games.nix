{ config, pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    #inputs.nix-gaming.packages.${pkgs.system}.wine-tkg

    gamemode # Optimise Linux system performance on demand
    wine # overlay wine
    winetricks
    cabextract
    dxvk
    vkd3d-proton
    protontricks
    #vkd3d
    #pyfa
    gamemode
    libstrangle
    vulkan-loader
    vulkan-validation-layers
    vulkan-tools
    legendary-gl # A free and open-source Epic Games Launcher alternative
    teamspeak_client # voip client
    #cemu
    jstest-gtk
    linuxConsoleTools

    # scripts
    fish-throw

    discord-canary
  ];

  programs.steam.enable = true;
  hardware.steam-hardware.enable = true;
  programs.steam.remotePlay.openFirewall = true;
  programs.steam.dedicatedServer.openFirewall = true;

  services.joycond.enable = true;
}
