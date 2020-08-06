# Kuro -- my desktop

{ pkgs, options, config, ... }:

let secrets = import ./secrets.nix;
in {
  imports = [
    ../personal.nix # common settings
    ./hardware-configuration.nix
  ];

  modules = {
    desktop = {
      bspwm.enable = true;

      apps.rofi.enable = true;
      apps.discord.enable = true;
      # apps.skype.enable = true;
      apps.daw.enable = true; # making music
      apps.graphics.enable = true; # raster/vector/sprites
      apps.recording.enable = true; # recording screen/audio
      #apps.vm.enable = true;         # virtualbox for testing

      term.default = "termite";
      term.termite.enable = true;

      browsers.default = "google-chrome";
      browsers.firefox.enable = true;
      # browsers.qutebrowser.enable = true;
      # browsers.vimb.enable = true;

      # gaming.emulators.psx.enable = true;
      gaming.steam.enable = true;
    };

    editors = {
      default = "nvim";
      emacs.enable = true;
      vim.enable = true;
    };

    dev = { node.enable = true; };

    media = {
      mpv.enable = true;
      spotify.enable = true;
    };

    shell = {
      direnv.enable = true;
      git.enable = true;
      gnupg.enable = true;
      # weechat.enable = true;
      pass.enable = true;
      tmux.enable = true;
      ranger.enable = true;
      zsh.enable = true;
    };

    services = { };

    # themes.aquanaut.enable = true;
    themes.fluorescence.enable = true;
  };

  services = {
    postgresql = {
      enable = true;
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all ::1/128 trust
      '';
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE ${secrets.postgresql.username} WITH LOGIN PASSWORD '${secrets.postgresql.password}' CREATEDB;
        CREATE DATABASE nixcloud;
        GRANT ALL PRIVILEGES ON DATABASE nixcloud TO nixcloud;
      '';
    };
  };
  programs.ssh.startAgent = true;
  networking.networkmanager.enable = true;
  networking.hostId = "8425e349";
  time.timeZone = "Europe/Berlin";
}
