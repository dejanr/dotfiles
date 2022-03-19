{ pkgs , lib , ... }:

let
  username = "dejanr";
  githubKeys = builtins.fetchurl {
    name = "github-ssh-keys";
    url = "https://api.github.com/users/${username}/keys";
    sha256 = "1a10ilqfidhs590hjrs0clz2di9czhaf77fhvqcrmzslp5148kpg"; };
in
{
  nix.extraOptions = ''
    gc-keep-outputs = false
    gc-keep-derivations = false
    auto-optimise-store = true
    experimental-features = nix-command flakes
  '';
  nix.settings.substituters = [ https://cache.nixos.org ];
  nix.trusted-users = [ "${username}" "root" ];
  nix.package = pkgs.unstable.nixVersions.nix_2_7

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowUnsupportedSystem = true;
      android_sdk.accept_license = true;
      permittedInsecurePackages = [
        "p7zip-16.02"
      ];
    };
  };

  time.timeZone = "Europe/Berlin";
  time.hardwareClockInLocalTime = true;

  environment.systemPackages = with pkgs; [
    # nixpkgs
    direnv # A shell extension that manages your environment
    gitAndTools.diff-so-fancy # Good looking diffs
    gitAndTools.gitFull # Distributed version control system
    delta # A syntax-highlighting pager for git
    haskellPackages.gitHUD # command-line HUD for git repos
    htop # An interactive process viewer for Linux
    fd # A simple, fast and user-friendly alternative to find
    niv # dependency manager for nix projects
    nodejs-16_x
    ripgrep
    rsync #  A fast incremental file transfer utility
    tmux # Terminal multiplexer
    vimHugeX # vim with clipboard and x support
    wget # Tool for retrieving files
    unzip # An extraction utility for archives compressed in .zip format
    zip # Compressor/archiver for creating and modifying zipfiles
  ];

  users = {
    mutableUsers = true;
    users."${username}" = {
      description = "Dejan Ranisavljevic";
      name = username;
      initialHashedPassword = "";
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

      openssh.authorizedKeys.keys = with builtins; (
        map (x: x.key) (fromJSON (readFile githubKeys))
      );
    };
  };

  services.openssh.authorizedKeysFiles = [ "/home/${username}/.ssh/authorized_keys" ];

  programs.mosh.enable = true;
  programs.vim.defaultEditor = true;
  programs.ssh = {
    startAgent = true;
  };

  networking = {
    networkmanager.enable = true;

    timeServers = ["time.cloudflare.com"];

    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
      ];
      allowedTCPPortRanges = [
      ];
      allowedUDPPorts = [
      ];
      logRefusedConnections = false;
      allowedUDPPortRanges = [];
      connectionTrackingModules = [];
    };
  };

  console = {
    font = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
    keyMap = "us";
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "de_DE.UTF-8/UTF-8" "sr_RS@latin/UTF-8" ];
  };

  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable = true;
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    {
      domain = "*";
      type = "soft";
      item = "nofile";
      value = "4096";
    }
  ];

  systemd.extraConfig = "DefaultLimitNOFILE=1048576";
}
