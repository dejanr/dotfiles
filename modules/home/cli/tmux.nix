{
  pkgs,
  lib,
  config,
  ...
}:

with lib;

let
  cfg = config.modules.home.cli.tmux;
  colors = config.lib.stylix.colors;
  fileMimeTypes = [
    "text/plain"
    "text/x-nix"
    "text/x-go"
    "text/x-python"
    "text/x-shellscript"
    "text/x-c"
    "text/x-c++"
    "text/x-rust"
    "text/javascript"
    "application/javascript"
    "application/json"
    "application/toml"
    "application/yaml"
    "text/yaml"
  ];

  tmuxNewWorktree = pkgs.writeShellApplication {
    name = "tmux-new-worktree";
    runtimeInputs = with pkgs; [
      coreutils
      git
      gnused
      tmux
    ];
    text = builtins.readFile ./tmux/new-worktree.sh;
  };

  tmuxOpenNvimLink = pkgs.buildGoModule {
    pname = "tmux-open-nvim-link";
    version = "1.0.0";
    src = ./tmux/open-nvim-link;
    vendorHash = null;

    nativeBuildInputs = [ pkgs.makeWrapper ];
    nativeCheckInputs = [
      pkgs.tmux
      pkgs.neovim
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.glib ];
    preCheck = lib.optionalString pkgs.stdenv.isLinux ''
      export XDG_DATA_DIRS=${pkgs.shared-mime-info}/share
    '';
    postInstall = ''
      wrapProgram "$out/bin/tmux-open-nvim-link" \
        --prefix PATH : ${
          lib.makeBinPath ([ pkgs.tmux ] ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.libnotify ])
        } \
        --suffix PATH : ${lib.makeBinPath [ pkgs.neovim ]}
    '';
  };
in
{
  options.modules.home.cli.tmux = {
    enable = mkEnableOption "tmux";
    fileOpener.enable = mkEnableOption "open local text files in tmux Neovim through the Linux system opener";
  };

  config = mkIf cfg.enable {
    home.packages = [
      tmuxNewWorktree
      tmuxOpenNvimLink
    ];

    assertions = [
      {
        assertion = !cfg.fileOpener.enable || pkgs.stdenv.isLinux;
        message = "The tmux file opener is only supported on Linux.";
      }
    ];

    xdg.desktopEntries.tmux-nvim = mkIf cfg.fileOpener.enable {
      name = "Neovim (tmux)";
      exec = "${tmuxOpenNvimLink}/bin/tmux-open-nvim-link --local %u";
      icon = "nvim";
      terminal = false;
      noDisplay = true;
      categories = [
        "Utility"
        "TextEditor"
      ];
      mimeType = fileMimeTypes;
    };

    xdg.mimeApps = mkIf cfg.fileOpener.enable {
      enable = true;
      defaultApplications = genAttrs fileMimeTypes (_: "tmux-nvim.desktop");
    };

    programs.tmux = {
      enable = true;
      sensibleOnTop = false;

      prefix = "C-s";
      escapeTime = 0;
      historyLimit = 50000;
      terminal = "tmux-256color";
      focusEvents = true;
      baseIndex = 1;
      keyMode = "vi";
      mouse = true;
      aggressiveResize = false;
      customPaneNavigationAndResize = true;
      resizeAmount = 5;

      extraConfig = import ./tmux/config.nix { inherit colors tmuxNewWorktree tmuxOpenNvimLink; };
    };
  };
}
