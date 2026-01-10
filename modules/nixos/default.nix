{
  pkgs,
  inputs,
  lib,
  importsFrom,
  ...
}:

let
  username = "dejanr";
in
{
  imports = importsFrom { path = ./.; };

  services = {
    xserver.desktopManager.xterm.enable = false;

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = [ "--ssh" ];
    };
  };

  environment.systemPackages = with pkgs; [
    acpi
    tlp
    git
    t
    ddcutil # Query and change Linux monitor settings using DDC/CI and USB
  ];

  # Install fonts
  fonts = {
    packages = with pkgs; [
      jetbrains-mono
      roboto
      openmoji-color
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

  nix = {
    settings = {
      auto-optimise-store = true;
      allowed-users = [ "dejanr" ];
      trusted-users = [
        "${username}"
        "root"
      ];

      substituters = [
        # "ssh://nix-cache"
        "https://cache.nixos.org"
        # "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "ot-nix-cache:C6ZY7QNJHk8tAcyi00y0n3UhbnZvBxJE993/J61omU4="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
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

    package = lib.mkForce inputs.nix.outputs.packages.${pkgs.stdenv.hostPlatform.system}.nix;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnsupportedSystem = true;
      android_sdk.accept_license = true;
      permittedInsecurePackages = [ ];
    };
  };

  # Set up locales (timezone and keyboard layout)
  time.timeZone = "Europe/Berlin";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "de_DE.UTF-8/UTF-8"
      "sr_RS@latin/UTF-8"
    ];
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Set environment variables
  environment.variables = {
    PATH = "/run/current-system/sw/bin:$PATH";
    GOPATH = "$HOME/go";
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

  programs.zsh.enable = true;

  users = {
    mutableUsers = true;

    groups.i2c = {
      name = "i2c";
      members = [ username ];
    };

    users."${username}" = {
      description = "Dejan Ranisavljevic";
      name = username;
      group = "users";
      extraGroups = [
        "i2c"
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
        "nginx"
        "adbusers"
        "libvirtd"
        "qemu-libvirtd"
      ];
      packages = [ pkgs.hello ];
      isNormalUser = true;
      home = "/home/${username}";
      createHome = true;
      shell = pkgs.zsh;

      openssh.authorizedKeys.keyFiles = [
        inputs.ssh-keys.outPath
      ];
    };
  };

  services.openssh.authorizedKeysFiles = [ "/home/${username}/.ssh/authorized_keys" ];

  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c"
  '';

  # Do not touch
  system.stateVersion = "23.11";
}
