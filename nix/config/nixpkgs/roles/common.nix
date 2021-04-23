{ pkgs , lib , ... }:

let
  sources = import ../../../sources.nix;
  nixpkgs = sources.nixpkgs;
  username = "dejanr";
  githubKeys = builtins.fetchurl {
    name = "github-ssh-keys";
    url = "https://api.github.com/users/${username}/keys";
    sha256 = "0dg9rys45494i0y627i2qrjmwy59hm40zn76j2rf1539fqp7wrf9"; };
  emacs-overlay = (import sources.emacs-overlay);
  overlays =
    let
      paths = [
        ../overlays
      ];
    in with builtins;
    concatMap (
      path:
        (
          map (n: import (path + ("/" + n)))
            (
              filter (
                n: match ".*\\.nix" n != null
                || pathExists (path + ("/" + n + "/default.nix"))
              )
                (attrNames (readDir path))
            )
        )
    ) paths;
in
{
  nix.extraOptions = ''
    gc-keep-outputs = false
    gc-keep-derivations = false
    auto-optimise-store = true
    experimental-features = nix-command flakes
  '';
  nix.binaryCaches = [ https://cache.nixos.org ];
  nix.trustedUsers = [ "${username}" "root" ];
  nix.nixPath = [
    "nixos-config=/etc/nixos/configuration.nix"
    "nixpkgs=${nixpkgs}"
    "home-manager=${sources."home-manager"}"
  ];
  nix.package = pkgs.nixFlakes;

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
    overlays = overlays ++ [ emacs-overlay ];
  };

  time.timeZone = "Europe/Berlin";

  environment.systemPackages = with pkgs; [
    # scripts
    t
    wm-lock
    wm-wallpaper
    music
    youtube-dl

    # nixpkgs
    apg # Tools for random password generation
    bc # GNU software calculator
    direnv # A shell extension that manages your environment
    font-manager # Simple font management for GTK+ desktop environments
    gitAndTools.diff-so-fancy # Good looking diffs
    gitAndTools.gitFull # Distributed version control system
    #gnvim # GUI for neovim, without any web bloat
    grobi # Automatically configure monitors/outputs for Xorg via RANDR
    fzf # fuzzy finder
    haskellPackages.gitHUD # command-line HUD for git repos
    htop # An interactive process viewer for Linux
    keychain
    fd # A simple, fast and user-friendly alternative to find
    linuxPackages.cpupower # Tool to examine and tune power saving features
    niv # dependency manager for nix projects
    nodejs-15_x
    neovim
    pixz # A parallel compressor/decompressor for xz format
    psmisc # A set of small useful utilities that use the proc filesystem (such as fuser, killall and pstree)
    pwgen # Password generator which creates passwords which can be easily memorized by a human
    ripgrep
    rsync #  A fast incremental file transfer utility
    rxvt
    rxvt_unicode
    tmux # Terminal multiplexer
    unzip # An extraction utility for archives compressed in .zip format
    urxvt_font_size
    urxvt_perl
    urxvt_perls
    urxvt_vtwheel
    x2goclient # x2go client for remote desktop
    vimHugeX # vim with clipboard and x support
    wget # Tool for retrieving files
    zip # Compressor/archiver for creating and modifying zipfiles
  ];

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
        "libvirtd"
        "transmission"
        "plex"
        "adbusers"
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
    extraConfig = ''
      Host pocket
        HostName 10.147.17.10
        User dejanr
      Host home
        HostName 10.147.17.20
        User dejanr
      Host homelab
        HostName 10.147.17.30
        User dejanr
      Host theory
        HostName 10.147.17.40
        User dejanr
    '';
  };

  networking = {
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [
        # incoming connections allowed
        22 # ssh
        9418 # tor
        25565 # minecraft server
        80
        443
        631 # CUPS ports
        8625 # wireguard
        3000
        4000
        5000
        5900 # VNC
        22000 # syntching transfer
        8200 # minidlna xbox
        56789 # kam server
      ];
      allowedTCPPortRanges = [
        # castnow
        { from = 4100; to = 4105; }
      ];
      allowedUDPPorts = [
        631 # CUPS ports
        5353
        4445 # minecraft discovery
        21027 # syntching discovery
        1900 # minidlna xbox
        56789 # kam server
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

  security.pki = {
    caCertificateBlacklist = [
      "WoSign"
      "WoSign China"
      "CA WoSign ECC Root"
      "Certification Authority of WoSign G2"
    ];

    certificateFiles = let
      p = "/home/${username}/.mitmproxy/mitmproxy-ca.pem";
      mitmCA = if builtins.pathExists p then
        [ (builtins.toFile "mitmproxy-ca.pem" (builtins.readFile p)) ]
      else
        [];
      CAs = [];
    in mitmCA ++ CAs;
  };

  systemd.extraConfig = "DefaultLimitNOFILE=1048576";
}
