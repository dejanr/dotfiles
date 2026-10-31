{
  pkgs,
  preferences,
  wallpaper,
}:

let
  jsonFormat = pkgs.formats.json { };
  widget = id: widgetType: config: {
    inherit id widgetType;
    enabled = true;
    config = {
      displayPreferences = [ "all" ];
      syncPositionAcrossScreens = true;
    }
    // config;
  };
  settings = jsonFormat.generate "settings.json" {
    inherit (preferences)
      currentThemeName
      fontFamily
      monoFontFamily
      radiusStrength
      clockFormat
      showSeconds
      ;
    lockScreenFontFamily = preferences.fontFamily;
    lockDateFormat = "dddd, d MMMM";
    wallpaperFillMode = "Fill";
    weatherEnabled = false;
    lockScreenShowWeather = false;
    greeterWidgetInstances = [
      (widget "greeter_clock" "desktopClock" {
        style = "digital";
        weight = 300;
        twoTone = true;
        showDate = true;
        showDigitalSeconds = false;
        transparency = 0;
      })
      (widget "greeter_auth" "lockAuth" {
        style = "pill";
        profileVisibility = "always";
        passwordVisibility = "always";
      })
      (widget "greeter_status" "lockStatus" {
        showWeather = false;
        background = false;
      })
      (widget "greeter_power" "lockPower" {
        shape = "round";
      })
      (widget "greeter_session" "greeterSession" { })
    ];
  };
  session = jsonFormat.generate "session.json" {
    isLightMode = false;
    wallpaperPath = wallpaper;
    perModeWallpaper = false;
    perMonitorWallpaper = false;
    desktopWidgetInstancePositions.greeter_clock._synced = {
      x = 0;
      y = 0.09;
      anchorX = "center";
      anchorY = "start";
      width = 440;
      height = 176;
    };
  };
in
pkgs.linkFarm "dms-greeter-config" [
  {
    name = "settings.json";
    path = settings;
  }
  {
    name = "session.json";
    path = session;
  }
]
