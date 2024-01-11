{ config, pkgs, inputs, ... }:

let
  wine = (inputs.nix-gaming.packages.${pkgs.system}.wine-ge.overrideAttrs
    (old: {
      dontStrip = true;
      debug = true;
    })).override {
      supportFlags = {
        gettextSupport = true;
        fontconfigSupport = true;
        alsaSupport = true;
        openglSupport = true;
        vulkanSupport = true;
        tlsSupport = true;
        cupsSupport = true;
        dbusSupport = true;
        cairoSupport = true;
        cursesSupport = true;
        saneSupport = true;
        pulseaudioSupport = true;
        udevSupport = true;
        xineramaSupport = true;
        sdlSupport = true;
        mingwSupport = true;
        gtkSupport = true;
        gstreamerSupport = false;
        openalSupport = false;
        openclSupport = false;
        odbcSupport = false;
        netapiSupport = false;
        vaSupport = false;
        pcapSupport = false;
        v4lSupport = false;
        gphoto2Support = false;
        krb5Support = false;
        ldapSupport = false;
        vkd3dSupport = true;
        embedInstallers = false;
        waylandSupport = false;
        usbSupport = true;
        x11Support = true;
      };
    };
in {
  environment.systemPackages = [
    # wine
    inputs.nix-gaming.packages.${pkgs.system}.dxvk
    inputs.nix-gaming.packages.${pkgs.system}.vkd3d-proton
    inputs.nix-gaming.packages.${pkgs.system}.wineprefix-preparer

    pkgs.entropia

    pkgs.gamemode # Optimise Linux system performance on demand
    pkgs.mangohud # A Vulkan and OpenGL overlay for monitoring FPS, temperatures, CPU/GPU load and more
    pkgs.wine # overlay wine
    #winetricks
    pkgs.cabextract
    #dxvk
    #vkd3d-proton
    #protontricks
    #vkd3d
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
