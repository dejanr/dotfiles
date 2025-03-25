{ pkgs, inputs, ... }:

let
  username = "dejanr";
in
{
  imports = [
    ./secrets.nix
  ];

  environment = {
    defaultPackages = [ ];
  };

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

      defaultFonts = { emoji = [ "OpenMoji Color" ]; };
    };
  };

  # Nix settings, auto cleanup and enable flakes
  nix = {
    settings = {
      auto-optimise-store = true;
      allowed-users = [ "dejanr" ];
      trusted-public-keys = [
        "nixbuild.net/ororatech-swuerl-1:pIlkdwXcQ4rhAhyI17SLno25zgfeWFbBPBnA0jvIXyM="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
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

    package = pkgs.nixVersions.latest;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnsupportedSystem = true;
      android_sdk.accept_license = true;
      permittedInsecurePackages = [ "nix-2.15.3" ];
    };
  };

  # Set up locales (timezone and keyboard layout)
  time.timeZone = "Europe/Berlin";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales =
      [ "en_US.UTF-8/UTF-8" "de_DE.UTF-8/UTF-8" "sr_RS@latin/UTF-8" ];
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
    pam.loginLimits = [{
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "4096";
    }];
  };

  systemd.extraConfig = "DefaultLimitNOFILE=1048576";

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
        "adbusers"
        "libvirtd"
        "qemu-libvirtd"
      ];
      isNormalUser = true;
      home = "/home/${username}";
      createHome = true;
      shell = pkgs.zsh;

      openssh.authorizedKeys.keyFiles = [
        inputs.ssh-keys.outPath
      ];
    };
  };

  services.openssh.authorizedKeysFiles =
    [ "/home/${username}/.ssh/authorized_keys" ];

  services.udev.extraRules = ''
    KERNEL=="i2c-[0-9]*", GROUP="i2c"
  '';

  # Do not touch
  system.stateVersion = "23.11";
}
