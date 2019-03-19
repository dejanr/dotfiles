{ config, pkgs, ... }:

let
  unstableTarball = fetchTarball https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;
in
{
  time.timeZone = "Europe/Berlin";

  fonts = {
    enableFontDir = true;
    fonts = with pkgs; [
      pragmatapro
    ];
  };

  environment.systemPackages = with pkgs; [
    t # tmux session script
    apg # Tools for random password generation
    bash
    bash-completion
    nix-bash-completions
    haskellPackages.gitHUD # command-line HUD for git repos
    linuxPackages.cpupower # Tool to examine and tune power saving features
    wget # Tool for retrieving files
    neovim
    vimHugeX
    rsync #	A fast incremental file transfer utility
    unzip # An extraction utility for archives compressed in .zip format
    zip # Compressor/archiver for creating and modifying zipfiles
    gitAndTools.gitFull # Distributed version control system
    gitAndTools.diff-so-fancy # Good looking diffs
    htop # An interactive process viewer for Linux
    pixz # A parallel compressor/decompressor for xz format
    psmisc # A set of small useful utilities that use the proc filesystem (such as fuser, killall and pstree)
    pwgen # Password generator which creates passwords which can be easily memorized by a human
    tmux # Terminal multiplexer
    bc # GNU software calculator
    nixops # NixOS cloud provisioning and deployment tool
    rxvt
    rxvt_unicode
    urxvt_vtwheel
    urxvt_font_size
    urxvt_perl
    urxvt_perls
    font-manager # Simple font management for GTK+ desktop environments
  ];

  users = {
    mutableUsers = true;
    extraUsers.dejanr = {
      description = "Dejan Ranisavljevic";
      name = "dejanr";
      group = "users";
      extraGroups = [
				"lp" "kmem"
				"wheel" "disk"
				"audio" "video"
				"networkmanager"
				"systemd-journal"
				"vboxusers" "docker"
				"utmp" "adm" "input"
				"tty" "floppy" "uucp"
				"cdrom" "tape" "dialout"
        "libvirtd"
        "transmission" "plex"
        "adbusers"
			];
      shell = "/run/current-system/sw/bin/bash";
      home = "/home/dejanr";
      createHome = true;
    };
  };

  services.openssh.authorizedKeysFiles = ["/home/dejanr/.ssh/authorized_keys" "/etc/nixos/authorized_keys"];

  programs.mosh.enable = true;
  programs.vim.defaultEditor = true;
  programs.ssh.startAgent = true;

  networking = {
    networkmanager.enable = true;

    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPorts = [ # incoming connections allowed
        22   # ssh
        9418 # tor
        25565 # minecraft server
        80
        443
        3000
        4000
        5000
      ];
      allowedTCPPortRanges = [
        # castnow
        { from = 4100; to = 4105; }
      ];
      allowedUDPPorts = [
        5353
        4445 # minecraft discovery
      ];
      allowedUDPPortRanges = [];
      connectionTrackingModules = [];
    };
  };

  i18n = {
    consoleFont = "${pkgs.terminus_font}/share/consolefonts/ter-u28n.psf.gz";
    consoleKeyMap = "us";
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [ "en_US.UTF-8/UTF-8" "de_DE.UTF-8/UTF-8" "sr_RS@latin/UTF-8" ];
  };

  hardware = {
    cpu.intel.updateMicrocode = true;

    opengl.driSupport = true;
    opengl.driSupport32Bit = true;

    firmware = [
      pkgs.firmwareLinuxNonfree
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable = true;
  security.rtkit.enable = true;

  security.pam.loginLimits = [{
    domain = "*";
    type = "soft";
    item = "nofile";
    value = "4096";
  }];

  nixpkgs.config = {
    android_sdk.accept_license = true;
    config.allowBroken = true;

    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  nix = {
    extraOptions = ''
      gc-keep-outputs = false
      gc-keep-derivations = false
      auto-optimise-store = true
    '';
  };
}
