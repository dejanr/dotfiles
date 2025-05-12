{ config, pkgs, inputs, ... }:

let
  dxvk = inputs.nix-gaming.packages.${pkgs.system}.dxvk;
  wineprefix-preparer = inputs.nix-gaming.packages.${pkgs.system}.wineprefix-preparer;
  wine = (inputs.nix-gaming.packages.${pkgs.system}.wine-ge.overrideAttrs (old: {
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
      gtkSupport = false;
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
      vkd3dSupport = false;
      embedInstallers = false;
      waylandSupport = true;
      usbSupport = true;
      x11Support = true;
    };
  };
in
{
  environment.systemPackages = [
    pkgs.appimage-run
    wine
    pkgs.dxvk
    pkgs.vkd3d-proton
    pkgs.wine-prefix

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

    inputs.nix-gaming.packages.${pkgs.system}.star-citizen

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
