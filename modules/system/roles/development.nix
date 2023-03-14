{ inputs, config, pkgs, ... }:

{
  programs.java = { enable = true; package = pkgs.jdk11; };

  environment.systemPackages = with pkgs; [
    ack
    aspell
    aspellDicts.de
    aspellDicts.en
    altair
    atop
    autoconf
    autojump # cd command that learns
    automake
    awscli
    alacritty
    s3cmd
    s3fs
    s3fs
    bash
    bind
    binutils
    clang # A c, c++, objective-c, and objective-c++ frontend for the llvm compiler (wrapper script)
    cmake
    connect # Make network connection via SOCKS and https proxy
    coreutils
    ctags
    curl
    dpkg
    docker
    docker-compose
    exercism # A Go based command line tool for exercism.io
    file # show file type
    fish
    fzf
    gist # Upload code to github gist from cli
    gcc
    graphicsmagick # Swiss army knife of image processing
    gdb
    gforth
    git
    gitAndTools.git-extras
    gitAndTools.gitflow
    gitFull
    gnumake
    gnum4 # GNU M4, a macro processor
    go
    gparted
    gh # github cli tool
    htop
    haskellPackages.ghc # The Glasgow Haskell Compiler
    haskellPackages.cabal-install # The command-line interface for Cabal and Hackage
    iftop
    imagemagickBig
    iotop
    llvm
    lshw
    lsof
    jq # A lightweight and flexible command-line JSON processor
    mercurial
    mosh # mobile shell, ssh replacement
    mr # multiple repository managment
    nixfmt
    opam # A package manager for OCaml
    ocamlPackages.ocaml # Most popular variant of the Caml language
    ocamlPackages.core # Jane Street Capital's standard library overlay
    ocamlPackages.ounit # Unit test framework for OCaml
    ocamlPackages.utop # Universal toplevel for OCaml
    ocamlPackages.reason # Facebook's friendly syntax to OCaml
    pulumi
    ncftp
    ngrep # network packet alalyzer
    nix-prefetch-scripts
    nmap # network discovery and security audit
    nox # tools to make nix nicer
    nodejs-18_x # nodejs
    yarn
    obs-studio # video recording and live streaming
    sshuttle # Transparent proxy server that works as a poor man's VPN
    silver-searcher
    sqlite
    patchelf
    psmisc
    python3
    ranger # file manager with minimal ncurses interface
    ruby
    ripgrep
    smartmontools # tools for monitoring hard drives
    tcpdump # network sniffer
    inetutils
    tmux
    tree
    tldr # Simplified and community-driven man pages
    usbutils
    wget
    which
    wireshark # network protocol analyzer
    inputs.mach-nix.packages.${pkgs.system}.mach-nix # python env management
  ];

  programs.adb.enable = true;
}
