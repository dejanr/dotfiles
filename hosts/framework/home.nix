{
  config,
  pkgs,
  lib,
  ...
}:

let
  moonlightOmegaHost = "omega.cat-vimba.ts.net";
  moonlightOmegaLanProfileArgs = [
    "--resolution"
    "2560x1600"
    "--fps"
    "120"
    "--bitrate"
    "80000"
    "--display-mode"
    "fullscreen"
  ];
  moonlightOmega4kProfileArgs = [
    "--4K"
    "--fps"
    "120"
    "--bitrate"
    "120000"
    "--display-mode"
    "fullscreen"
  ];

  moonlightOmegaPair = pkgs.writeShellScriptBin "moonlight-omega-pair" ''
    host=${lib.escapeShellArg moonlightOmegaHost}
    exec ${pkgs.moonlight-qt}/bin/moonlight pair "$@" "$host"
  '';

  moonlightOmegaList = pkgs.writeShellScriptBin "moonlight-omega-list" ''
    host=${lib.escapeShellArg moonlightOmegaHost}
    exec ${pkgs.moonlight-qt}/bin/moonlight list "$@" "$host"
  '';

  moonlightOmegaDesktop = pkgs.writeShellScriptBin "moonlight-omega-desktop" ''
    host=${lib.escapeShellArg moonlightOmegaHost}
    exec ${pkgs.moonlight-qt}/bin/moonlight stream ${lib.escapeShellArgs moonlightOmegaLanProfileArgs} "$@" "$host" Desktop
  '';

  moonlightOmegaDesktop4k = pkgs.writeShellScriptBin "moonlight-omega-desktop-4k" ''
    host=${lib.escapeShellArg moonlightOmegaHost}
    exec ${pkgs.moonlight-qt}/bin/moonlight stream ${lib.escapeShellArgs moonlightOmega4kProfileArgs} "$@" "$host" Desktop
  '';
in
{
  imports = [ ../../modules/home/default.nix ];

  config.home.packages = with pkgs; [
    slack
    moonlight-qt
    moonlightOmegaPair
    moonlightOmegaList
    moonlightOmegaDesktop
    moonlightOmegaDesktop4k
  ];

  config.services.demo-it.enable = true;

  config.modules = {
    home.common.packages.enable = true;

    home.secrets.agenix.enable = true;

    home.gui.xdg = {
      enable = true;
      autostart."1password" = {
        name = "1Password";
        exec = "1password --silent";
      };
      disabledAutostartEntries = [
        "caffeine.desktop"
        "pulseaudio.desktop"
      ];
    };
    home.gui.desktop.enable = true;
    home.gui.browser.qutebrowser.enable = true;
    home.gui.niri = {
      enable = true;
      defaultsOutOfStore = false;
    };

    apps.kitty.enable = true;
    apps.ghostty.enable = true;

    home.cli.direnv.enable = true;
    home.cli.git.enable = true;
    home.cli.dev.enable = true;
    home.cli.nixvim.enable = true;
    home.cli.tmux.enable = true;
    home.cli.zsh.enable = true;
    home.cli.yazi.enable = true;
    home.cli.codex.enable = true;
    home.cli.pi-mono.enable = true;

    home.cli.llama-cpp = {
      enable = true;
      package = pkgs.framework-llama-cpp;
      gpuLayers = 999;
      flashAttention = true;
      noMmap = true;
    };
  };

  config.services.cliphist = {
    enable = true;
    systemdTargets = [ "niri.service" ];
  };

  config.xdg.configFile = {
    "DankMaterialShell/settings.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hosts/framework/config/dms/settings.json";
    };
    "DankMaterialShell/plugin_settings.json" = {
      force = true;
      source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hosts/framework/config/dms/plugin_settings.json";
    };
  };

  config.home.file."dms-session" = {
    force = true;
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/hosts/framework/config/dms/session.json";
    target = ".local/state/DankMaterialShell/session.json";
  };

  config.xdg.desktopEntries = {
    moonlight-omega-desktop = {
      name = "Moonlight Omega Desktop (LAN)";
      exec = "moonlight-omega-desktop";
      icon = "moonlight";
      terminal = false;
      categories = [
        "Game"
        "Network"
      ];
    };
    moonlight-omega-desktop-4k = {
      name = "Moonlight Omega Desktop (4K LAN)";
      exec = "moonlight-omega-desktop-4k";
      icon = "moonlight";
      terminal = false;
      categories = [
        "Game"
        "Network"
      ];
    };
    moonlight-omega-pair = {
      name = "Moonlight Pair Omega";
      exec = "moonlight-omega-pair";
      icon = "moonlight";
      terminal = true;
      categories = [
        "Game"
        "Network"
      ];
    };
  };

  config.home.stylix.theme = "catppuccin-mocha";
}
