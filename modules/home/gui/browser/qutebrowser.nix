{
  config,
  pkgs,
  lib,
  osConfig ? null,
  ...
}:

with lib;

let
  cfg = config.modules.home.gui.browser.qutebrowser;
  osConfig' = if osConfig == null then { } else osConfig;
  xserverVideoDrivers = attrByPath [ "services" "xserver" "videoDrivers" ] [ ] osConfig';
  hasXDriver = driver: elem driver xserverVideoDrivers;
  detectedGpu =
    if hasAttrByPath [ "hardware" "asahi" ] osConfig' then "apple"
    else if hasXDriver "nvidia" then "nvidia"
    else if hasXDriver "amdgpu" || hasXDriver "ati" || attrByPath [ "hardware" "amdgpu" "initrd" "enable" ] false osConfig' then "amd"
    else if hasXDriver "intel" || hasXDriver "i915" then "intel"
    else "none";
  effectiveGpu = if cfg.gpu == "auto" then detectedGpu else cfg.gpu;

  generateHomepage =
    name: font: config: # html
    ''
      <!DOCTYPE html>
          <html>
          <head>
            <title>Dashboard</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
              body {
                background-color: #${config.lib.stylix.colors.base00};
              }
              .profile {
                font-family: ${font};
                font-size: 14px;
                text-align: right;
                color: #${config.lib.stylix.colors.base08};
                line-height: 1.35;
                margin-top: 0;
                margin-bottom: 0;
              }
        </style>
      </head>
      <body><p class="profile"><b>${name}</b></p></body>
      </html>
    '';
in
{
  options.modules.home.gui.browser.qutebrowser = {
    enable = mkEnableOption "qutebrowser";

    gpu = mkOption {
      type = types.enum [ "auto" "nvidia" "apple" "intel" "amd" "none" ];
      default = "auto";
      description = "GPU vendor for hardware acceleration flags. Uses host auto-detection by default.";
    };
  };

  config = mkIf cfg.enable (
    let
      qutebrowserPkg =
        if effectiveGpu == "nvidia" then pkgs.qutebrowser-nvidia
        else pkgs.qutebrowser-unstable;
      webpageBg =
        if config.stylix.polarity == "dark" then config.lib.stylix.colors.withHashtag.base07
        else config.lib.stylix.colors.withHashtag.base00;
    in
    {

    home.sessionVariables = optionalAttrs (effectiveGpu == "nvidia") {
      LIBVA_DRIVER_NAME = "nvidia";
      NVD_BACKEND = "direct";
      MOZ_DISABLE_RDD_SANDBOX = "1";
    };

    home.shellAliases = {
      qutebrowser = "QT_QPA_PLATFORM=wayland QSG_RHI_BACKEND=opengl qutebrowser -B ~/.browser/Personal";
    };

    xdg.mimeApps.defaultApplications = {
      "text/html" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/http" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/https" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/about" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/unknown" = "org.qutebrowser.qutebrowser.desktop";
    };

    programs.qutebrowser.enable = true;
    programs.qutebrowser.package = qutebrowserPkg;

    programs.qutebrowser.settings = {
      window.transparent = false;
      window.hide_decoration = true;
      auto_save.session = false;
      # Set window/UI background colors early to prevent artifacts
      colors.tabs.bar.bg = config.lib.stylix.colors.withHashtag.base00;
      colors.statusbar.normal.bg = config.lib.stylix.colors.withHashtag.base00;
      colors.completion.even.bg = config.lib.stylix.colors.withHashtag.base00;
      colors.webpage.bg = webpageBg;

      # === PERFORMANCE SETTINGS ===
      # Faster scrolling
      scrolling.smooth = false;
      # Reduce memory - don't keep pages in memory when switching tabs
      content.cache.size = 52428800; # 50MB cache
      # Faster completion
      completion.shrink = true;
      completion.use_best_match = true;
      # Disable animations
      tabs.show_switching_delay = 0;
      # Lazy load tabs on restore (huge speedup)
      session.lazy_restore = true;
    };

    programs.qutebrowser.extraConfig =
      let
        gpuFeatures = {
          nvidia = "VaapiVideoDecoder,VaapiVideoEncoder,VaapiVideoDecodeLinuxGL,VaapiOnNvidiaGPUs,VaapiIgnoreDriverChecks,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE";
          intel = "VaapiVideoDecoder,VaapiVideoEncoder,VaapiVideoDecodeLinuxGL";
          amd = "VaapiVideoDecoder,VaapiVideoEncoder,VaapiVideoDecodeLinuxGL";
          apple = "";
          none = "";
        };
        gpuDisableFeatures = {
          nvidia = "UseChromeOSDirectVideoDecoder";
          intel = "UseChromeOSDirectVideoDecoder";
          amd = "UseChromeOSDirectVideoDecoder";
          apple = "";
          none = "";
        };
        enableFeatures = gpuFeatures.${effectiveGpu};
        disableFeatures = gpuDisableFeatures.${effectiveGpu};
        enableFeaturesArg = optionalString (enableFeatures != "") "'enable-features=${enableFeatures}',";
        disableFeaturesArg = optionalString (disableFeatures != "") "'disable-features=${disableFeatures}',";
      in
      ''
      config.set('qt.args',[
        # NOTE: qutebrowser prepends '--' to each arg, so do NOT include '--' here
        # Process model: each tab gets its own process (isolates crashes/hangs)
        'process-per-tab',
        # Performance
        'disable-background-networking',
        'disable-sync',
        'disable-extensions',
        'disable-default-apps',
        # Renderer process limits - kill tabs that use too much memory (512MB)
        'renderer-process-limit=20',
        # Hardware acceleration
        ${enableFeaturesArg}
        ${disableFeaturesArg}
        'enable-gpu-rasterization',
        'enable-zero-copy',
        'ignore-gpu-blocklist',
      ])
      config.load_autoconfig(True)

      # === FREEZE PREVENTION SETTINGS ===
      
      # Ad blocking (biggest impact - blocks heavy tracking/ad scripts)
      c.content.blocking.enabled = True
      c.content.blocking.method = 'both'
      c.content.blocking.adblock.lists = [
        "https://easylist.to/easylist/easylist.txt",
        "https://easylist.to/easylist/easyprivacy.txt",
        "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/filters.txt",
        "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/badware.txt",
        "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/privacy.txt",
        "https://raw.githubusercontent.com/uBlockOrigin/uAssets/master/filters/resource-abuse.txt",
      ]
      
      # Limit JavaScript capabilities
      c.content.javascript.clipboard = 'none'
      
      # Reduce WebRTC overhead
      c.content.webrtc_ip_handling_policy = 'default-public-interface-only'

      # Let websites use their default color scheme
      c.colors.webpage.preferred_color_scheme = 'auto'

      # === ADDITIONAL PERFORMANCE ===
      # Disable preloading - saves memory and CPU
      c.content.prefers_reduced_motion = True
      
      # Limit history for faster searches
      c.completion.web_history.max_items = 1000
      
      # Disable DNS prefetching
      c.content.dns_prefetch = False
      
      # Disable hyperlink auditing (tracking)
      c.content.hyperlink_auditing = False
      
      # Canvas reading enabled (disabling breaks canvas-based apps like Figma, Google Maps, etc.
      # and provides minimal fingerprinting protection on its own)
      c.content.canvas_reading = True
      
      # Disable geolocation
      c.content.geolocation = False
      
      # Disable notifications
      c.content.notifications.enabled = False
      
      # Disable autoplay - huge performance saver
      c.content.autoplay = False
      
      # Limit concurrent tabs loading
      c.tabs.background = True

      base00 = "#''
    + config.lib.stylix.colors.base00
    + ''
      "
      base01 = "#''
    + config.lib.stylix.colors.base01
    + ''
      "
      base02 = "#''
    + config.lib.stylix.colors.base02
    + ''
      "
      base03 = "#''
    + config.lib.stylix.colors.base03
    + ''
      "
      base04 = "#''
    + config.lib.stylix.colors.base04
    + ''
      "
      base05 = "#''
    + config.lib.stylix.colors.base05
    + ''
      "
      base06 = "#''
    + config.lib.stylix.colors.base06
    + ''
      "
      base07 = "#''
    + config.lib.stylix.colors.base07
    + ''
      "
      base08 = "#''
    + config.lib.stylix.colors.base08
    + ''
      "
      base09 = "#''
    + config.lib.stylix.colors.base09
    + ''
      "
      base0A = "#''
    + config.lib.stylix.colors.base0A
    + ''
      "
      base0B = "#''
    + config.lib.stylix.colors.base0B
    + ''
      "
      base0C = "#''
    + config.lib.stylix.colors.base0C
    + ''
      "
      base0D = "#''
    + config.lib.stylix.colors.base0D
    + ''
      "
      base0E = "#''
    + config.lib.stylix.colors.base0E
    + ''
      "
      base0F = "#''
    + config.lib.stylix.colors.base0F
    + ''
      "

      config.set('content.cookies.accept', 'no-3rdparty', 'chrome-devtools://*')
      config.set('content.cookies.accept', 'no-3rdparty', 'devtools://*')

      config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}; rv:90.0) Gecko/20100101 Firefox/90.0', 'https://accounts.google.com/*')
      config.set('content.headers.user_agent', 'Mozilla/5.0 ({os_info}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99 Safari/537.36', 'https://*.slack.com/*')

      config.set('content.images', True, 'chrome-devtools://*')
      config.set('content.images', True, 'devtools://*')

      config.set('content.javascript.enabled', True, 'chrome-devtools://*')
      config.set('content.javascript.enabled', True, 'devtools://*')
      config.set('content.javascript.enabled', True, 'chrome://*/*')
      config.set('content.javascript.enabled', True, 'qute://*/*')

      c.tabs.favicons.scale = 1.0
      c.tabs.last_close = 'close'
      c.tabs.position = 'left'
      c.tabs.width = '3%'

      c.url.default_page = str(config.configdir)+'/qute-home.html'
      c.url.start_pages = str(config.configdir)+'/qute-home.html'

      c.url.searchengines['google'] = 'https://encrypted.google.com/search?q={}'
      c.url.searchengines['g'] = c.url.searchengines['google']
      c.url.searchengines['gl'] = 'https://encrypted.google.com/search?btnI=1&q={}&sourceid=navclient&gfns=1'
      c.url.searchengines['DEFAULT'] = c.url.searchengines['google']
      c.url.searchengines['gimg'] = 'http://www.google.de/search?tbm=isch&hl=de&source=hp&q={}'

      c.url.searchengines['duckduckgo'] = 'https://duckduckgo.com/?q={}'
      c.url.searchengines['d'] = c.url.searchengines['duckduckgo']

      c.url.searchengines['amazon'] = 'https://www.amazon.com/s?k={}'
      c.url.searchengines['am'] = c.url.searchengines['amazon']

      c.url.searchengines['mynixos'] = 'https://mynixos.com/search?q={}'
      c.url.searchengines['mn'] = c.url.searchengines['mynixos']

      c.url.searchengines['nixpkg'] = 'https://github.com/search?q=repo%3ANixOS%2Fnixpkgs%20{}&type=code'
      c.url.searchengines['np'] = c.url.searchengines['nixpkg']

      c.url.searchengines['wikipedia'] = 'https://en.wikipedia.org/w/index.php?fulltext=1&search={}&title=Special%3ASearch&ns0=1'
      c.url.searchengines['wp'] = c.url.searchengines['wikipedia']

      c.url.searchengines['yt'] = 'https://www.youtube.com/results?search_query={}'
      c.url.searchengines['gd'] = 'https://drive.google.com/drive/search?q={}'
      c.url.searchengines['gh'] = 'https://github.com/search?q={}&type=repositories'

      c.url.searchengines['th'] = 'https://www.thingiverse.com/search?q={}&page=1'
      c.url.searchengines['pp'] = 'https://www.printables.com/search/models?q={}'

      config.set('completion.open_categories',["searchengines","quickmarks","bookmarks","history"])

      config.set('downloads.location.directory', '~/downloads')

      config.set('fileselect.handler', 'external')
      config.set('fileselect.single_file.command', ['kitty', '--class=file_chooser', '-e', 'yazi', '--chooser-file={}'])
      config.set('fileselect.multiple_files.command', ['kitty', '--class=file_chooser', '-e', 'yazi', '--chooser-file={}'])
      config.set('fileselect.folder.command', ['kitty', '--class=file_chooser', '-e', 'yazi', '--chooser-file={}'])

      config.bind('<Ctrl-p>', 'completion-item-focus prev', mode='command')
      config.bind('<Ctrl-n>', 'completion-item-focus next', mode='command')

      config.unbind('d')
      config.bind('t', 'open -t')
      config.bind('x', 'tab-close')
      config.bind('yf', 'hint links yank')
      config.bind('<Ctrl-Shift-i>', 'devtools')

      # save quickmark
      config.bind('<space>q', 'cmd-set-text -s :quickmark-add {url} "{title}"')

      # spawn external programs
      config.bind(',m', 'hint links spawn mpv {hint-url}')

      # Quick recovery keybindings for frozen tabs
      config.bind(',k', 'tab-close')  # Kill current tab quickly
      config.bind(',r', 'reload -f')  # Force reload (bypasses cache)

      # theming
      c.colors.completion.fg = base05
      c.colors.completion.odd.bg = base01
      c.colors.completion.even.bg = base00
      c.colors.completion.category.fg = base0A
      c.colors.completion.category.bg = base00
      c.colors.completion.category.border.top = base00
      c.colors.completion.category.border.bottom = base00
      c.colors.completion.item.selected.fg = base05
      c.colors.completion.item.selected.bg = base02
      c.colors.completion.item.selected.border.top = base02
      c.colors.completion.item.selected.border.bottom = base02
      c.colors.completion.item.selected.match.fg = base0B
      c.colors.completion.match.fg = base0B
      c.colors.completion.scrollbar.fg = base05
      c.colors.completion.scrollbar.bg = base00
      c.colors.contextmenu.disabled.bg = base01
      c.colors.contextmenu.disabled.fg = base04
      c.colors.contextmenu.menu.bg = base00
      c.colors.contextmenu.menu.fg =  base05
      c.colors.contextmenu.selected.bg = base02
      c.colors.contextmenu.selected.fg = base05
      c.colors.downloads.bar.bg = base00
      c.colors.downloads.start.fg = base00
      c.colors.downloads.start.bg = base0D
      c.colors.downloads.stop.fg = base00
      c.colors.downloads.stop.bg = base0C
      c.colors.downloads.error.fg = base08
      c.colors.hints.fg = base00
      c.colors.hints.bg = base0A
      c.colors.hints.match.fg = base05
      c.colors.keyhint.fg = base05
      c.colors.keyhint.suffix.fg = base05
      c.colors.keyhint.bg = base00
      c.colors.messages.error.fg = base00
      c.colors.messages.error.bg = base08
      c.colors.messages.error.border = base08
      c.colors.messages.warning.fg = base00
      c.colors.messages.warning.bg = base0E
      c.colors.messages.warning.border = base0E
      c.colors.messages.info.fg = base05
      c.colors.messages.info.bg = base00
      c.colors.messages.info.border = base00
      c.colors.prompts.fg = base05
      c.colors.prompts.border = base00
      c.colors.prompts.bg = base00
      c.colors.prompts.selected.bg = base02
      c.colors.prompts.selected.fg = base05
      c.colors.statusbar.normal.fg = base0B
      c.colors.statusbar.normal.bg = base00
      c.colors.statusbar.insert.fg = base00
      c.colors.statusbar.insert.bg = base0D
      c.colors.statusbar.passthrough.fg = base00
      c.colors.statusbar.passthrough.bg = base0C
      c.colors.statusbar.private.fg = base00
      c.colors.statusbar.private.bg = base01
      c.colors.statusbar.command.fg = base05
      c.colors.statusbar.command.bg = base00
      c.colors.statusbar.command.private.fg = base05
      c.colors.statusbar.command.private.bg = base00
      c.colors.statusbar.caret.fg = base00
      c.colors.statusbar.caret.bg = base0E
      c.colors.statusbar.caret.selection.fg = base00
      c.colors.statusbar.caret.selection.bg = base0D
      c.colors.statusbar.progress.bg = base0D
      c.colors.statusbar.url.fg = base05
      c.colors.statusbar.url.error.fg = base08
      c.colors.statusbar.url.hover.fg = base05
      c.colors.statusbar.url.success.http.fg = base0C
      c.colors.statusbar.url.success.https.fg = base0B
      c.colors.statusbar.url.warn.fg = base0E
      c.colors.tabs.bar.bg = base00
      c.colors.tabs.indicator.start = base0D
      c.colors.tabs.indicator.stop = base0C
      c.colors.tabs.indicator.error = base08
      c.colors.tabs.odd.fg = base05
      c.colors.tabs.odd.bg = base01
      c.colors.tabs.even.fg = base05
      c.colors.tabs.even.bg = base00
      c.colors.tabs.pinned.even.bg = base0C
      c.colors.tabs.pinned.even.fg = base07
      c.colors.tabs.pinned.odd.bg = base0B
      c.colors.tabs.pinned.odd.fg = base07
      c.colors.tabs.pinned.selected.even.bg = base02
      c.colors.tabs.pinned.selected.even.fg = base05
      c.colors.tabs.pinned.selected.odd.bg = base02
      c.colors.tabs.pinned.selected.odd.fg = base05
      c.colors.tabs.selected.odd.fg = base05
      c.colors.tabs.selected.odd.bg = base02
      c.colors.tabs.selected.even.fg = base05
      c.colors.tabs.selected.even.bg = base02

      font = "''
    + config.stylix.fonts.monospace.name
    + ''
      "
      c.fonts.default_family = font
      c.fonts.default_size = '14pt'

      c.fonts.web.family.standard = font
      c.fonts.web.family.serif = font
      c.fonts.web.family.sans_serif = font
      c.fonts.web.family.fixed = font
      c.fonts.web.family.fantasy = font
      c.fonts.web.family.cursive = font
    '';

    home.file.".config/qutebrowser/containers".text = ''
      Personal
      Futurice
      Work
      Gaming
    '';

    home.file.".browser/Personal/config/qute-home.html".text =
      generateHomepage "Personal" config.stylix.fonts.monospace.name
        config;
    home.file.".browser/Futurice/config/qute-home.html".text =
      generateHomepage "Futurice" config.stylix.fonts.monospace.name
        config;
    home.file.".browser/Work/config/qute-home.html".text =
      generateHomepage "Work" config.stylix.fonts.monospace.name
        config;
    home.file.".browser/AGENTS/config/qute-home.html".text =
      generateHomepage "AGENTS" config.stylix.fonts.monospace.name
        config;

    home.file.".browser/Personal/config/config.py".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/qutebrowser/config.py";
    home.file.".browser/Futurice/config/config.py".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/qutebrowser/config.py";
    home.file.".browser/Work/config/config.py".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/qutebrowser/config.py";

    home.file.".browser/Default".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.browser/Personal";

    home.file.".browser/Personal/config/userscripts".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/qutebrowser/userscripts";
    home.file.".browser/Futurice/config/userscripts".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/qutebrowser/userscripts";
    home.file.".browser/Work/config/userscripts".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/qutebrowser/userscripts";

    xdg.desktopEntries = mkIf pkgs.stdenv.isLinux {
      "org.qutebrowser.qutebrowser" = {
        name = "qutebrowser";
        genericName = "Web Browser";
        exec = "qutebrowser -B ${config.home.homeDirectory}/.browser/Personal %u";
        terminal = false;
        categories = [
          "Application"
          "Network"
          "WebBrowser"
        ];
        mimeType = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
      };
    };
  });
}
