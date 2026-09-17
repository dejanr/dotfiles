{
  config,
  inputs,
  lib,
  ...
}:

let
  cfg = config.modules.home.cli.hunk;
  colors = config.lib.stylix.colors;
  tint =
    percent: color:
    "#"
    +
      lib.concatMapStrings
        (
          offset:
          let
            background = lib.fromHexString (builtins.substring offset 2 colors.base00);
            foreground = lib.fromHexString (builtins.substring offset 2 color);
            channel = builtins.div (background * (100 - percent) + foreground * percent + 50) 100;
          in
          lib.toLower (lib.fixedWidthString 2 "0" (lib.toHexString channel))
        )
        [
          0
          2
          4
        ];
in
{
  imports = [ inputs.hunk.homeManagerModules.default ];

  options.modules.home.cli.hunk = {
    enable = lib.mkEnableOption "Hunk terminal diff viewer";
  };

  config = lib.mkIf cfg.enable {
    programs.hunk = {
      enable = true;
      settings = {
        theme = lib.mkDefault "stylix";
        menu_bar = lib.mkDefault false;
        hunk_headers = lib.mkDefault false;
        prompt_save_view_preferences = lib.mkDefault false;
        themes.stylix = lib.mkDefault {
          base = if config.stylix.polarity == "light" then "github-light-default" else "github-dark-default";
          label = "Stylix";
          background = "#${colors.base00}";
          panel = "#${colors.base01}";
          panelAlt = tint 4 colors.base05;
          border = "#${colors.base03}";
          accent = "#${colors.base0D}";
          accentMuted = "#${colors.base02}";
          text = "#${colors.base05}";
          muted = "#${colors.base04}";
          addedBg = tint 12 colors.base0B;
          removedBg = tint 12 colors.base08;
          movedAddedBg = tint 12 colors.base0D;
          movedRemovedBg = tint 12 colors.base0D;
          contextBg = "#${colors.base00}";
          addedContentBg = tint 24 colors.base0B;
          removedContentBg = tint 24 colors.base08;
          contextContentBg = "#${colors.base00}";
          addedSignColor = "#${colors.base0B}";
          removedSignColor = "#${colors.base08}";
          lineNumberBg = "#${colors.base00}";
          lineNumberFg = "#${colors.base04}";
          selectedHunk = "#${colors.base02}";
          badgeAdded = "#${colors.base0B}";
          badgeRemoved = "#${colors.base08}";
          badgeNeutral = "#${colors.base0D}";
          fileNew = "#${colors.base0B}";
          fileDeleted = "#${colors.base08}";
          fileRenamed = "#${colors.base0A}";
          fileModified = "#${colors.base0E}";
          fileUntracked = "#${colors.base0C}";
          noteBorder = "#${colors.base0E}";
          noteBackground = "#${colors.base01}";
          noteTitleBackground = "#${colors.base02}";
          noteTitleText = "#${colors.base05}";
          syntax_scopes = {
            comment = "#${colors.base03}";
            "punctuation.definition.comment" = "#${colors.base03}";
            keyword = "#${colors.base0E}";
            "keyword.operator" = "#${colors.base05}";
            storage = "#${colors.base0E}";
            string = "#${colors.base0B}";
            "constant.numeric" = "#${colors.base09}";
            "constant.language" = "#${colors.base09}";
            "constant.character.escape" = "#${colors.base0F}";
            "entity.name.function" = "#${colors.base0D}";
            "support.function" = "#${colors.base0D}";
            "entity.name.type" = "#${colors.base0A}";
            "support.type" = "#${colors.base0A}";
            variable = "#${colors.base08}";
            punctuation = "#${colors.base05}";
          };
        };
      };
    };
  };
}
