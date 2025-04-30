{ inputs, config, pkgs, ... }:

{
  programs.java = {
    enable = true;
    package = pkgs.jdk11;
  };

  environment.systemPackages = with pkgs; [
    ack
    aspell
    aspellDicts.de
    aspellDicts.en
    atop
    awscli2
    aider-chat # AI pair programming in your terminal
    bind
    binutils
    bruno # Open-source IDE For exploring and testing APIs.
    cargo # Downloads your Rust project's dependencies and builds your project
    rustup # rust toolchain
    conda # python package managment
    coreutils
    ctags
    curl
    code-cursor # AI-powered code editor built on vscode
    claude-code # An agentic coding tool that lives in your terminal, understands your codebase, and helps you code faster
    exercism # A Go based command line tool for exercism.io
    zed-editor
    file # show file type
    gdb
    gforth
    gh # github cli tool
    gist # Upload code to github gist from cli
    git-lfs # Git extension for versioning large files
    gitAndTools.git-extras
    gitAndTools.gitflow
    gitFull
    lazygit
    gnum4 # GNU M4, a macro processor
    gnumake
    gcc
    go
    gofumpt # Stricter gofmt
    gotools # Additional tools for Go development
    gparted
    graphicsmagick # Swiss army knife of image processing
    htop
    icdiff
    iftop
    imagemagickBig
    inetutils
    iotop
    jq # A lightweight and flexible command-line JSON processor
    lshw
    lsof
    lua
    lua54Packages.lua
    lua54Packages.luarocks
    mercurial
    meshcommander # A faster, bundled version of MeshCommander that runs on localhost in a browser.
    mosh # mobile shell, ssh replacement
    mr # multiple repository managment
    ncftp
    ngrep # network packet alalyzer
    nix-prefetch-scripts
    nixpkgs-fmt # Nix code formatter for nixpkgs
    nmap # network discovery and security audit
    nodejs_20 # nodejs
    nox # tools to make nix nicer
    (wrapOBS {
      plugins = [
        obs-studio-plugins.obs-vintage-filter
        obs-studio-plugins.obs-vertical-canvas
        obs-studio-plugins.obs-pipewire-audio-capture
        # obs-studio-plugins.obs-nvfbc
        obs-studio-plugins.obs-gradient-source
        obs-studio-plugins.obs-freeze-filter
        obs-studio-plugins.obs-composite-blur
        obs-studio-plugins.obs-backgroundremoval
        obs-studio-plugins.obs-3d-effect
        obs-studio-plugins.input-overlay
      ];
    })
    ocamlPackages.core # Jane Street Capital's standard library overlay
    ocamlPackages.ocaml # Most popular variant of the Caml language
    ocamlPackages.ounit # Unit test framework for OCaml
    ocamlPackages.reason # Facebook's friendly syntax to OCaml
    ocamlPackages.utop # Universal toplevel for OCaml
    opam # A package manager for OCaml
    python3Packages.huggingface-hub # Download and publish models and other files on the huggingface.co hub
    portaudio # Portable cross-platform Audio API
    #python3Packages.vllm
    patchelf
    psmisc
    pulumi
    python3
    picocom # Minimal dumb-terminal emulation program
    ripgrep
    ruby
    s3cmd
    s3fs
    s3fs
    silver-searcher
    smartmontools # tools for monitoring hard drives
    sqlite
    tcpdump # network sniffer
    tldr # Simplified and community-driven man pages
    tmux
    tree
    usbutils
    wget
    which
    wireshark # network protocol analyzer
    yarn
    pnpm

    cht-sh

    # gleam
    gleam
    erlang
    rebar3
  ];

  programs.adb.enable = true;
}
