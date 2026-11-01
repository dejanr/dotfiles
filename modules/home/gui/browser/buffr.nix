{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.gui.browser.buffr;
  toml = pkgs.formats.toml { };
  launcher =
    profile: name:
    pkgs.writeShellScriptBin name ''
      export BUFFR_PROFILE_LABEL=${lib.escapeShellArg profile}
      export XDG_DATA_HOME=${lib.escapeShellArg "${config.xdg.dataHome}/buffr-profiles/${profile}"}
      export XDG_CACHE_HOME=${lib.escapeShellArg "${config.xdg.cacheHome}/buffr-profiles/${profile}"}
      exec ${lib.getExe cfg.package} --config ${lib.escapeShellArg "${config.xdg.configHome}/buffr/config.toml"} "$@"
    '';
  personal = launcher "Personal" "buffr";
  work = launcher "Work" "buffr-work";
  mimeTypes = [
    "text/html"
    "text/xml"
    "application/xhtml+xml"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
  ];
  desktopEntry = name: command: {
    inherit name;
    genericName = "Web Browser";
    exec = "${command} %U";
    icon = "${cfg.package}/share/icons/hicolor/256x256/apps/buffr.png";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = mimeTypes;
    settings.StartupWMClass = "sh.kryptic.buffr";
  };
in
{
  options.modules.home.gui.browser.buffr = {
    enable = lib.mkEnableOption "Buffr browser";
    package = lib.mkPackageOption pkgs "buffr" { };
    settings = lib.mkOption {
      type = toml.type;
      default = { };
      description = "Buffr settings shared by the separate Personal and Work profiles.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      personal
      work
    ];
    home.sessionVariables.BROWSER = "${personal}/bin/buffr";

    xdg.configFile."buffr/config.toml".source = toml.generate "buffr-config.toml" cfg.settings;
    xdg.mimeApps = {
      enable = true;
      defaultApplications = lib.genAttrs mimeTypes (_: "sh.kryptic.buffr.desktop");
    };
    xdg.desktopEntries = {
      "sh.kryptic.buffr" = desktopEntry "Buffr (Personal)" "${personal}/bin/buffr";
      "sh.kryptic.buffr.work" = desktopEntry "Buffr (Work)" "${work}/bin/buffr-work";
    };
  };
}
