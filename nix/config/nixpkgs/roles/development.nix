{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ag
    ack
    aspell
    aspellDicts.de
    aspellDicts.en
    atop
    autoconf
    autojump # cd command that learns
    automake
    awscli
    alacritty
    s3cmd
    s3fs
    unfs3
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
    docker_compose
    exercism # A Go based command line tool for exercism.io
    file # show file type
    fish
    fzf
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
    opam # A package manager for OCaml
    ocamlPackages.ocaml # Most popular variant of the Caml language
    ocamlPackages.core # Jane Street Capital's standard library overlay
    ocamlPackages.ounit # Unit test framework for OCaml
    ocamlPackages.utop # Universal toplevel for OCaml
    ocamlPackages.reason # Facebook's friendly syntax to OCaml
    ncftp
    ngrep # network packet alalyzer
    nix-prefetch-scripts
    nmap # network discovery and security audit
    nodejs-12_x # Event-driven I/O framework for the V8 JavaScript engine
    nox # tools to make nix nicer
    obs-studio # video recording and live streaming
    sshuttle # Transparent proxy server that works as a poor man's VPN
    patchelf
    psmisc
    python
    ranger # file manager with minimal ncurses interface
    ruby
    smartmontools # tools for monitoring hard drives
    tcpdump # network sniffer
    telnet
    tmux
    tree
    tldr # Simplified and community-driven man pages
    usbutils
    wget
    which
    wireshark # network protocol analyzer
  ];

  programs.adb.enable = true;
}
