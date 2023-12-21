{ pkgs, ... }:

let
  username = "dejanr";
  githubKeys = builtins.fetchurl {
    name = "github-ssh-keys";
    url = "https://api.github.com/users/${username}/keys";
    sha256 = "15a0vmngmp3453nk7a6jd8kyph4qhcfzljdsrank3h9fgbf12xng";
  };
in
  {
    environment = {
      defaultPackages = [ ];
    };

    services = {
      xserver.desktopManager.xterm.enable = false;

      tailscale = {
        enable = true;
        useRoutingFeatures = "both";
        extraUpFlags = ["--ssh"];
      };
    };

    environment.systemPackages = with pkgs; [
      acpi tlp git t
    ];

    # Install fonts
    fonts = {
      packages = with pkgs; [
        jetbrains-mono
        roboto
        openmoji-color
        (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
      ];

      fontconfig = {
        enable = true;
        antialias = true;
        hinting = {
          autohint = false;
          enable = true;
        };

        subpixel.lcdfilter = "default";

        defaultFonts = {
          emoji = [ "OpenMoji Color" ];
        };
      };
    };

    # Nix settings, auto cleanup and enable flakes
    nix = {
      settings = {
        auto-optimise-store = true;
        allowed-users = [ "dejanr" ];
        substituters = [ "https://cache.nixos.org" ];
        trusted-users = [ "${username}" "root" ];
      };

      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };

      extraOptions = ''
            experimental-features = nix-command flakes
            keep-outputs = true
            keep-derivations = true
      '';

      package = pkgs.nixVersions.stable;
    };

    nixpkgs = {
      config = {
        allowUnfree = true;
        allowBroken = true;
        allowUnsupportedSystem = true;
        android_sdk.accept_license = true;
        permittedInsecurePackages = [
        ];
      };
    };

    # Set up locales (timezone and keyboard layout)
    time.timeZone = "Europe/Berlin";

    i18n = {
      defaultLocale = "en_US.UTF-8";
      supportedLocales = [ "en_US.UTF-8/UTF-8" "de_DE.UTF-8/UTF-8" "sr_RS@latin/UTF-8" ];
    };

    console = {
      font = "Lat2-Terminus16";
      keyMap = "us";
    };

    # Set environment variables
    environment.variables = {
      NIXOS_CONFIG = "$HOME/.config/nixos/configuration.nix";
      NIXOS_CONFIG_DIR = "$HOME/.config/nixos/";
      XDG_DATA_HOME = "$HOME/.local/share";
      PASSWORD_STORE_DIR = "$HOME/.local/share/password-store";
      GTK_RC_FILES = "$HOME/.local/share/gtk-1.0/gtkrc";
      GTK2_RC_FILES = "$HOME/.local/share/gtk-2.0/gtkrc";
      MOZ_ENABLE_WAYLAND = "1";
      ZK_NOTEBOOK_DIR = "$HOME/stuff/notes/";
      EDITOR = "nvim";
      DIRENV_LOG_FORMAT = "";
      ANKI_WAYLAND = "1";
      DISABLE_QT5_COMPAT = "0";
    };

    security = {
      sudo.wheelNeedsPassword = false;
      polkit.enable = true;
      rtkit.enable = true;
      pam.loginLimits = [
        {
          domain = "*";
          type = "soft";
          item = "nofile";
          value = "4096";
        }
      ];
    };

    systemd.extraConfig = "DefaultLimitNOFILE=1048576";

    programs.zsh.enable = true;

    users = {
      mutableUsers = true;

      users."${username}" = {
        description = "Dejan Ranisavljevic";
        name = username;
        group = "users";
        extraGroups = [
          "lp"
          "kmem"
          "wheel"
          "disk"
          "audio"
          "video"
          "networkmanager"
          "systemd-journal"
          "vboxusers"
          "docker"
          "utmp"
          "adm"
          "input"
          "tty"
          "floppy"
          "uucp"
          "cdrom"
          "tape"
          "dialout"
          "transmission"
          "plex"
          "adbusers"
          "libvirtd"
          "qemu-libvirtd"
        ];
        isNormalUser = true;
        home = "/home/${username}";
        createHome = true;
        shell = pkgs.zsh;

        openssh.authorizedKeys.keys = with builtins; (
          map (x: x.key) (fromJSON (readFile githubKeys))
        );
      };
    };

    services.openssh.authorizedKeysFiles = [ "/home/${username}/.ssh/authorized_keys" ];

    # Do not touch
    system.stateVersion = "23.11";
  }
