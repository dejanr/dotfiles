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

      # System monitoring
      atop
      htop
      iftop
      iotop
      lshw
      lsof
      psmisc
      smartmontools

      # Cloud and infrastructure
      awscli2
      pulumi
      s3cmd
      s3fs

      # AI and coding assistants
      aider-chat
      code-cursor
      claude-code
      codex

      # Network tools
      bind
      curl
      inetutils
      mosh
      ncftp
      ngrep
      nmap
      tcpdump
      wireshark

      # Version control
      lazygit
      gh
      gist
      mr

      # Programming languages and tools
      cargo
      go
      gofumpt
      gotools
      nodejs_20
      python3
      yarn-berry
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
      python3Packages.huggingface-hub
      conda

      # Development utilities
      ctags
      exercism
      file
      gforth
      gparted
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

      # Editors
      zed-editor

      # API testing
      bruno

      # OBS with plugins
      (wrapOBS {
        plugins = [
          obs-studio-plugins.obs-vintage-filter
          obs-studio-plugins.obs-pipewire-audio-capture
          obs-studio-plugins.obs-gradient-source
          obs-studio-plugins.obs-freeze-filter
          obs-studio-plugins.obs-composite-blur
          obs-studio-plugins.obs-backgroundremoval
          obs-studio-plugins.obs-3d-effect
          obs-studio-plugins.input-overlay
        ];
      })
    ];
  };
}
