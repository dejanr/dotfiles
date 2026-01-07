{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
let
  cfg = config.modules.home.cli.dev;

in
{
  options.modules.home.cli.dev = {
    enable = mkEnableOption "development tools";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Text processing and search
      ack
      ripgrep
      silver-searcher
      jq

      # Spell checking
      aspell
      aspellDicts.de
      aspellDicts.en

      ast-grep # grep by code

      # System monitoring
      htop
      iftop
      iotop
      lsof

      # Cloud and infrastructure
      awscli2
      pulumi
      s3cmd
      s3fs

      # AI and coding assistants
      aider-chat
      code-cursor
      opencode
      claude-code
      gemini-cli
      codex
      llama-cpp
      mermaid-cli

      # Network tools
      bind
      curl
      inetutils
      mosh
      ncftp
      ngrep
      nmap
      tcpdump

      # Version control
      lazygit
      gh
      gist
      mr

      # Programming languages and tools
      go
      gofumpt
      gotools
      nodejs_24
      python3
      pnpm

      # OCaml ecosystem
      ocamlPackages.core
      ocamlPackages.ocaml
      ocamlPackages.ounit
      ocamlPackages.reason
      ocamlPackages.utop
      opam

      # Gleam ecosystem
      gleam
      erlang
      rebar3

      # Python packages
      python312Packages.huggingface-hub

      # Development utilities
      ctags
      exercism
      file
      icdiff
      nix-prefetch-scripts
      nixpkgs-fmt
      nox
      picocom
      sqlite
      tldr
      tmux
      tree
      usbutils
      wget
      which

      # Image processing
      graphicsmagick
      imagemagickBig
      portaudio

      # API testing
      bruno
    ];
  };
}
