{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.home.gui.browser.chrome;
  launcher =
    profile:
    pkgs.writeShellScriptBin "chrome-${lib.toLower profile}" ''
      exec ${lib.getExe cfg.package} \
        --user-data-dir="''${XDG_DATA_HOME:-$HOME/.local/share}/chrome-profiles/${profile}" \
        --class=chrome-${lib.toLower profile} \
        --no-first-run \
        --no-default-browser-check \
        "$@"
    '';
  personal = launcher "Personal";
  work = launcher "Work";
  mimeTypes = [
    "text/html"
    "text/xml"
    "application/xhtml+xml"
    "x-scheme-handler/http"
    "x-scheme-handler/https"
    "x-scheme-handler/about"
    "x-scheme-handler/unknown"
  ];
  desktopEntry = profile: package: {
    name = "Google Chrome (${profile})";
    genericName = "Web Browser";
    exec = "${lib.getExe package} %U";
    icon = "google-chrome";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeType = mimeTypes;
    settings.StartupWMClass = "chrome-${lib.toLower profile}";
  };
in
{
  options.modules.home.gui.browser.chrome = {
    enable = lib.mkEnableOption "Google Chrome with separate Personal and Work profiles";
    package = lib.mkPackageOption pkgs "google-chrome" { };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      personal
      work
    ];
    home.sessionVariables.BROWSER = lib.getExe personal;

    xdg.mimeApps = {
      enable = true;
      defaultApplications = lib.genAttrs mimeTypes (_: "chrome-personal.desktop");
    };
    xdg.desktopEntries = {
      chrome-personal = desktopEntry "Personal" personal;
      chrome-work = desktopEntry "Work" work;
    };
  };
}
