{
  pkgs,
  lib,
  ...
}:

{
  imports = [ ../../modules/home/default.nix ];

  config.home.file."npmrc".text = ''
    prefix = ~/.npm-packages
  '';
  config.home.file."npmrc".target = ".npmrc";

  config.home.packages = with pkgs; [
    slack
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
    home.cli.pi-mono.enable = true;
    home.cli.pi-mono.voiceInput.device =
      "alsa_input.usb-R__DE_R__DE_VideoMic_Me-C__A37AFAC5-00.mono-fallback";
  };

  config.services.cliphist = {
    enable = true;
    systemdTargets = [ "niri.service" ];
  };


  config.xdg.configFile = {
    "DankMaterialShell/settings.json" = {
      force = true;
      source = ./config/dms/settings.json;
    };
    "DankMaterialShell/plugin_settings.json" = {
      force = true;
      source = ./config/dms/plugin_settings.json;
    };
  };

  config.home.stylix.theme = "catppuccin-mocha";
}
