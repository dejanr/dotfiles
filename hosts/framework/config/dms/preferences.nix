let
  control = id: {
    inherit id;
    enabled = true;
    w = 4;
    h = 1;
  };
in
{
  settings = {
    configVersion = 42;
    currentThemeName = "purple";
    currentThemeCategory = "generic";
    fontFamily = "Inter Variable";
    monoFontFamily = "Fira Code";
    clockFormat = "24h";
    showSeconds = false;
    weatherEnabled = true;
    useAutoLocation = false;
    useFahrenheit = false;
    windSpeedUnit = "kmh";
    audioVisualizerEnabled = true;
    audioWheelScrollAmount = 5;
    niriLayoutGapsOverride = 4;
    niriLayoutRadiusOverride = 4;
    niriLayoutBorderSize = 2;
    radiusStrength = 25;
    barElevationEnabled = false;
    blurredWallpaperLayer = false;
    blurWallpaperOnOverview = false;
    cursorSettings = {
      theme = "Adwaita";
      size = 24;
      niri = {
        hideWhenTyping = false;
        hideAfterInactiveMs = 0;
      };
    };
    iconThemePerMode = false;
    iconThemeDark = "System Default";
    iconThemeLight = "System Default";

    barConfigs = [
      {
        id = "default";
        name = "Main Bar";
        enabled = true;
        position = 0;
        screenPreferences = [ "all" ];
        showOnLastDisplay = true;
        leftWidgets = [
          "launcherButton"
          {
            id = "spacer";
            size = 8;
            enabled = true;
          }
          {
            id = "workspaceSwitcher";
            enabled = true;
            workspaceIndicatorCompact = true;
            showWorkspaceName = true;
            showWorkspaceIndex = false;
            showWorkspaceApps = false;
            showWorkspacePadding = false;
            showOccupiedWorkspacesOnly = true;
            workspaceDragReorder = true;
            maxWorkspaceIcons = 3;
            workspaceAppIconSizeOffset = 0;
            groupWorkspaceApps = true;
            workspaceFollowFocus = false;
            reverseScrolling = false;
            dwlShowAllTags = false;
            workspaceColorMode = "default";
            workspaceOccupiedColorMode = "none";
            workspaceUnfocusedColorMode = "default";
            workspaceUrgentColorMode = "default";
            workspaceFocusedBorderEnabled = false;
            workspaceFocusedBorderColor = "primary";
            workspaceFocusedBorderThickness = 2;
          }
          {
            id = "spacer";
            size = 8;
            enabled = true;
          }
          "focusedWindow"
        ];
        centerWidgets = [
          "music"
          "clock"
          "weather"
        ];
        rightWidgets = [
          "systemTray"
          "tailscale"
          "clipboard"
          "dejliScreenshotAction"
          "dejliGifStatus"
          "dejliAudioStatus"
          "cpuUsage"
          "memUsage"
          "notificationButton"
          "battery"
          {
            id = "controlCenterButton";
            enabled = true;
            showNetworkIcon = true;
            showVpnIcon = true;
            showBluetoothIcon = true;
            showAudioIcon = true;
            showAudioPercent = false;
            showMicIcon = false;
            showMicPercent = true;
            showBrightnessIcon = false;
            showBrightnessPercent = false;
            showBatteryIcon = false;
            showPrinterIcon = false;
            showScreenSharingIcon = true;
          }
        ];
        spacing = 4;
        innerPadding = 4;
        widgetPadding = 6;
        noBackground = true;
        scrollXBehavior = "focusWindow";
        scrollYBehavior = "workspace";
      }
    ];

    controlCenterWidgets = [
      {
        id = "user";
        enabled = true;
        w = 5;
        h = 1;
      }
      {
        id = "settings";
        enabled = true;
        w = 1;
        h = 1;
        small = true;
      }
      {
        id = "lock";
        enabled = true;
        w = 1;
        h = 1;
        small = true;
      }
      {
        id = "power";
        enabled = true;
        w = 1;
        h = 1;
        small = true;
      }
    ]
    ++ map control [
      "volumeSlider"
      "brightnessSlider"
      "wifi"
      "bluetooth"
      "audioOutput"
      "audioInput"
      "nightMode"
      "darkMode"
      "plugin_tailscale"
      "plugin_dejliScreenshotAction"
      "plugin_dejliGifStatus"
      "plugin_dejliAudioStatus"
    ]
    ++ [
      {
        id = "edit";
        enabled = true;
        w = 1;
        h = 1;
        small = true;
      }
      {
        id = "runningApps";
        enabled = true;
        w = 4;
        h = 1;
        small = true;
        col = 0;
        row = 8;
      }
    ];

    dockConfigs = [
      {
        id = "dock";
        name = "Dock";
        enabled = false;
        screenPreferences = [ "all" ];
      }
    ];
    workspaceNameIcons = builtins.listToAttrs (
      map
        (workspace: {
          name = workspace.id;
          value = {
            type = "icon";
            value = workspace.icon;
          };
        })
        [
          {
            id = "1";
            icon = "language";
          }
          {
            id = "2";
            icon = "code";
          }
          {
            id = "3";
            icon = "terminal";
          }
          {
            id = "4";
            icon = "terminal";
          }
          {
            id = "5";
            icon = "print";
          }
          {
            id = "6";
            icon = "help";
          }
          {
            id = "7";
            icon = "help";
          }
          {
            id = "8";
            icon = "help";
          }
          {
            id = "9";
            icon = "chat";
          }
          {
            id = "10";
            icon = "music_note";
          }
          {
            id = "11";
            icon = "videocam";
          }
        ]
    );
  };

  plugins = {
    dejliAudioStatus.src = ./plugins/DejliAudioStatus;
    dejliGifStatus.src = ./plugins/DejliGifStatus;
    dejliScreenshotAction.src = ./plugins/DejliScreenshotAction;
    tailscale = {
      src = ./plugins/Tailscale;
      settings = {
        refreshInterval = 5;
        upCommand = "tailscale up";
        downCommand = "tailscale down --accept-risk=lose-ssh";
      };
    };
  };
}
