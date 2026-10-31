{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;

let
  cfg = config.modules.apps.monstar;
  colors = config.lib.stylix.colors;
  configFormat = pkgs.formats.keyValue {
    listsAsDuplicateKeys = true;
    mkKeyValue = generators.mkKeyValueDefault { } " = ";
  };
in
{
  options.modules.apps.monstar = {
    enable = mkEnableOption "Monstar Wayland terminal";

    package = mkOption {
      type = types.package;
      default = inputs.monstar.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          ../../../overlays/90-apps/terminal-links/monstar-tmux-links.patch
        ];
        doCheck = true;
      });
      description = "Monstar package to install.";
    };

    settings = mkOption {
      type = configFormat.type;
      default = { };
      description = "Monstar configuration. Lists produce repeated keys.";
      example = {
        font-size = 14;
        background-opacity = 0.95;
        keybind = [
          "ctrl+shift+k=scroll_page_lines:-5"
          "ctrl+shift+j=scroll_page_lines:5"
        ];
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isLinux;
        message = "Monstar requires Linux and a Wayland session.";
      }
    ];

    fonts.fontconfig.enable = true;

    home.packages = [
      cfg.package
      config.stylix.fonts.monospace.package
    ];

    modules.apps.monstar.settings = {
      font-family = mkDefault config.stylix.fonts.monospace.name;
      font-size = mkDefault config.stylix.fonts.sizes.terminal;
      theme = mkDefault "stylix";
      linux-cgroup = mkDefault "always";
    };

    xdg.configFile = {
      "monstar/config".source = configFormat.generate "monstar-config" cfg.settings;
      "monstar/themes/stylix".source = configFormat.generate "monstar-stylix" {
        background = "#${colors.base00}";
        foreground = "#${colors.base05}";
        selection-background = "#${colors.base02}";
        selection-foreground = "#${colors.base05}";
        cursor-color = "#${colors.base05}";
        cursor-text = "#${colors.base00}";
        palette = imap0 (index: color: "${toString index}=#${color}") [
          colors.base00
          colors.base08
          colors.base0B
          colors.base0A
          colors.base0D
          colors.base0E
          colors.base0C
          colors.base05
          colors.base03
          colors.base08
          colors.base0B
          colors.base0A
          colors.base0D
          colors.base0E
          colors.base0C
          colors.base07
          colors.base09
        ];
      };
    };
  };
}
