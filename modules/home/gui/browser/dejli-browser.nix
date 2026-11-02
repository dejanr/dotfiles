{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.gui.browser.dejli-browser;
  toml = pkgs.formats.toml { };
  launcher =
    profile: name:
    pkgs.writeShellScriptBin name ''
      export DEJLI_BROWSER_PROFILE_LABEL=${lib.escapeShellArg profile}
      export XDG_DATA_HOME=${lib.escapeShellArg "${config.xdg.dataHome}/buffr-profiles/${profile}"}
      export XDG_CACHE_HOME=${lib.escapeShellArg "${config.xdg.cacheHome}/buffr-profiles/${profile}"}
      exec ${lib.getExe cfg.package} --config ${lib.escapeShellArg "${config.xdg.configHome}/dejli-browser/config.toml"} "$@"
    '';
  personal = launcher "Personal" "dejli-browser";
  work = launcher "Work" "dejli-browser-work";
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
    icon = "${cfg.package}/share/icons/hicolor/scalable/apps/dejli-browser.svg";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = mimeTypes;
    settings.StartupWMClass = "li.dej.browser";
  };
in
{
  options.modules.home.gui.browser.dejli-browser = {
    enable = lib.mkEnableOption "Dejli Browser";
    package = lib.mkPackageOption pkgs "dejli-browser" { };
    settings = lib.mkOption {
      type = toml.type;
      default = { };
      description = "Dejli Browser settings shared by the separate Personal and Work profiles.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      personal
      work
    ];
    home.sessionVariables.BROWSER = "${personal}/bin/dejli-browser";

    xdg.configFile."dejli-browser/config.toml".source =
      toml.generate "dejli-browser-config.toml" cfg.settings;
    xdg.mimeApps = {
      enable = true;
      defaultApplications = lib.genAttrs mimeTypes (_: "li.dej.browser.desktop");
    };
    xdg.desktopEntries = {
      "li.dej.browser" = desktopEntry "Dejli Browser (Personal)" "${personal}/bin/dejli-browser";
      "li.dej.browser.work" = desktopEntry "Dejli Browser (Work)" "${work}/bin/dejli-browser-work";
    };
  };
}
