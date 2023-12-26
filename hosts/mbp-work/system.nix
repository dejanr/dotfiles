{ pkgs, lib, ... }: {

  config = lib.mkIf pkgs.stdenv.isDarwin {

    #services.skhd = {
    #  enable = true;
    #  skhdConfig = builtins.readFile ./conf.d/skhdrc;
    #};

    system = {
      keyboard = {
        remapCapsLockToControl = true;
        enableKeyMapping = true;
      };

      defaults = {
        NSGlobalDomain = {

          # Set to dark mode
          AppleInterfaceStyle = "Dark";

          # Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
          AppleKeyboardUIMode = 3;

          # Automatically show and hide the menu bar
          _HIHideMenuBar = true;

          # Expand save panel by default
          NSNavPanelExpandedStateForSaveMode = true;

          # Expand print panel by default
          PMPrintingExpandedStateForPrint = true;

          # Replace press-and-hold with key repeat
          ApplePressAndHoldEnabled = false;

          # Set a fast key repeat rate
          KeyRepeat = 2;

          # Shorten delay before key repeat begins
          InitialKeyRepeat = 12;

          # Save to local disk by default, not iCloud
          NSDocumentSaveNewDocumentsToCloud = false;

          # Disable autocorrect capitalization
          NSAutomaticCapitalizationEnabled = false;

          # Disable autocorrect smart dashes
          NSAutomaticDashSubstitutionEnabled = false;

          # Disable autocorrect adding periods
          NSAutomaticPeriodSubstitutionEnabled = false;

          # Disable autocorrect smart quotation marks
          NSAutomaticQuoteSubstitutionEnabled = false;

          # Disable autocorrect spellcheck
          NSAutomaticSpellingCorrectionEnabled = false;
        };

        dock = {
          autohide = true;
          mouse-over-hilite-stack = true;
          mru-spaces = false;
          orientation = "left";
          show-recents = false;
          showhidden = true;
          static-only = true;
          tilesize = 84;
        };

        finder = {
          # Default Finder window set to column view
          FXPreferredViewStyle = "clmv";

          # Finder search in current folder by default
          FXDefaultSearchScope = "SCcf";

          # Disable warning when changing file extension
          FXEnableExtensionChangeWarning = false;

          # Allow quitting of Finder application
          QuitMenuItem = true;

          AppleShowAllFiles = true;
          AppleShowAllExtensions = true;
        };

        trackpad = {
            Clicking = false;
            TrackpadThreeFingerDrag = false;
        };

        # Disable "Are you sure you want to open" dialog
        LaunchServices.LSQuarantine = false;

        # universalaccess = {

        #   # Zoom in with Control + Scroll Wheel
        #   closeViewScrollWheelToggle = true;
        #   closeViewZoomFollowsFocus = true;
        # };

        # Where to save screenshots
        screencapture.location = "~/Downloads";

      };

      # Settings that don't have an option in nix-darwin
      activationScripts.postActivation.text = ''
        ###############################################################################
        # Finder                                                                      #
        ###############################################################################
        # Finder: disable window animations and Get Info animations
        defaults write com.apple.finder DisableAllAnimations -bool true
        # Set Desktop as the default location for new Finder windows
        # For other paths, use `PfLo` and `file:///full/path/here/`
        defaults write com.apple.finder NewWindowTarget -string "PfDe"
        defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/Desktop/"
        # Show icons for hard drives, servers, and removable media on the desktop
        defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
        defaults write com.apple.finder ShowHardDrivesOnDesktop -bool true
        defaults write com.apple.finder ShowMountedServersOnDesktop -bool true
        defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true
        # Finder: show status bar
        defaults write com.apple.finder ShowStatusBar -bool true
        # Finder: show path bar
        defaults write com.apple.finder ShowPathbar -bool true
        # Keep folders on top when sorting by name
        defaults write com.apple.finder _FXSortFoldersFirst -bool true
        # When performing a search, search the current folder by default
        defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
        # Avoid creating .DS_Store files on network or USB volumes
        defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
        defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
        # Automatically open a new Finder window when a volume is mounted
        defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
        defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true
        defaults write com.apple.finder OpenWindowForNewRemovableDisk -bool true
        # Use list view in all Finder windows by default
        # Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
        defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
        # Disable the warning before emptying the Trash
        defaults write com.apple.finder WarnOnEmptyTrash -bool false
        # Enable AirDrop over Ethernet and on unsupported Macs running Lion
        defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true
        # Show the ~/Library folder
        chflags nohidden ~/Library
        # Expand the following File Info panes:
        # “General”, “Open with”, and “Sharing & Permissions”
        defaults write com.apple.finder FXInfoPanesExpanded -dict \
            General -bool true \
            OpenWith -bool true \
            Privileges -bool true
        ###############################################################################
        # Dock, Dashboard, and hot corners                                            #
        ###############################################################################
        # Enable highlight hover effect for the grid view of a stack (Dock)
        defaults write com.apple.dock mouse-over-hilite-stack -bool true
        # Set the icon size of Dock items to 36 pixels
        defaults write com.apple.dock tilesize -int 36
        # Change minimize/maximize window effect
        defaults write com.apple.dock mineffect -string "scale"
        # Minimize windows into their application’s icon
        defaults write com.apple.dock minimize-to-application -bool true
        # Enable spring loading for all Dock items
        defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool true
        # Show indicator lights for open applications in the Dock
        defaults write com.apple.dock show-process-indicators -bool true
        # Don’t animate opening applications from the Dock
        defaults write com.apple.dock launchanim -bool false
        # Speed up Mission Control animations
        defaults write com.apple.dock expose-animation-duration -float 0.1
        # Don’t group windows by application in Mission Control
        # (i.e. use the old Exposé behavior instead)
        defaults write com.apple.dock expose-group-by-app -bool false
        # Disable Dashboard
        defaults write com.apple.dashboard mcx-disabled -bool true
        # Don’t show Dashboard as a Space
        defaults write com.apple.dock dashboard-in-overlay -bool true
        # Don’t automatically rearrange Spaces based on most recent use
        defaults write com.apple.dock mru-spaces -bool false
        # Remove the auto-hiding Dock delay
        defaults write com.apple.dock autohide-delay -float 0
        # Remove the animation when hiding/showing the Dock
        defaults write com.apple.dock autohide-time-modifier -float 0
        # Automatically hide and show the Dock
        defaults write com.apple.dock autohide -bool true
        # Make Dock icons of hidden applications translucent
        defaults write com.apple.dock showhidden -bool true
        # Don’t show recent applications in Dock
        defaults write com.apple.dock show-recents -bool false
        # Disable the Launchpad gesture (pinch with thumb and three fingers)
        #defaults write com.apple.dock showLaunchpadGestureEnabled -int 0
        ###############################################################################
        # Safari & WebKit                                                             #
        ###############################################################################
        # Privacy: don’t send search queries to Apple
        defaults write com.apple.Safari UniversalSearchEnabled -bool false
        defaults write com.apple.Safari SuppressSearchSuggestions -bool true
        # Press Tab to highlight each item on a web page
        defaults write com.apple.Safari WebKitTabToLinksPreferenceKey -bool true
        defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks -bool true
        # Show the full URL in the address bar (note: this still hides the scheme)
        defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true
        # Set Safari’s home page to `about:blank` for faster loading
        defaults write com.apple.Safari HomePage -string "about:blank"
        # Prevent Safari from opening ‘safe’ files automatically after downloading
        defaults write com.apple.Safari AutoOpenSafeDownloads -bool false
        # Allow hitting the Backspace key to go to the previous page in history
        defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled -bool true
        # Hide Safari’s bookmarks bar by default
        defaults write com.apple.Safari ShowFavoritesBar -bool false
        # Hide Safari’s sidebar in Top Sites
        defaults write com.apple.Safari ShowSidebarInTopSites -bool false
        # Disable Safari’s thumbnail cache for History and Top Sites
        defaults write com.apple.Safari DebugSnapshotsUpdatePolicy -int 2
        # Enable Safari’s debug menu
        defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
        # Make Safari’s search banners default to Contains instead of Starts With
        defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly -bool false
        # Remove useless icons from Safari’s bookmarks bar
        defaults write com.apple.Safari ProxiesInBookmarksBar "()"
        # Enable the Develop menu and the Web Inspector in Safari
        defaults write com.apple.Safari IncludeDevelopMenu -bool true
        defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
        defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
        # Add a context menu item for showing the Web Inspector in web views
        defaults write NSGlobalDomain WebKitDeveloperExtras -bool true
        # Enable continuous spellchecking
        defaults write com.apple.Safari WebContinuousSpellCheckingEnabled -bool true
        # Disable auto-correct
        defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false
        # Disable AutoFill
        defaults write com.apple.Safari AutoFillFromAddressBook -bool false
        defaults write com.apple.Safari AutoFillPasswords -bool false
        defaults write com.apple.Safari AutoFillCreditCardData -bool false
        defaults write com.apple.Safari AutoFillMiscellaneousForms -bool false
        # Warn about fraudulent websites
        defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true
        # Disable plug-ins
        defaults write com.apple.Safari WebKitPluginsEnabled -bool false
        defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled -bool false
        # Disable Java
        defaults write com.apple.Safari WebKitJavaEnabled -bool false
        defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled -bool false
        defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabledForLocalFiles -bool false
        # Block pop-up windows
        defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
        defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically -bool false
        # Enable “Do Not Track”
        defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true
        # Update extensions automatically
        defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true
        echo "Disable disk image verification"
        defaults write com.apple.frameworks.diskimages skip-verify -bool true
        defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
        defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

        echo "Avoid creating .DS_Store files on network volumes"
        defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

        echo "Disable the warning before emptying the Trash"
        defaults write com.apple.finder WarnOnEmptyTrash -bool false

        echo "Require password immediately after sleep or screen saver begins"
        defaults write com.apple.screensaver askForPassword -int 1
        defaults write com.apple.screensaver askForPasswordDelay -int 0

        echo "Allow apps from anywhere"
        SPCTL=$(spctl --status)
        if ! [ "$SPCTL" = "assessments disabled" ]; then
            sudo spctl --master-disable
        fi

        #################
        # General UI/UX #
        #################

        # Disable UI alert audio
        defaults write com.apple.systemsound "com.apple.sound.uiaudio.enabled" -int 0

        # Automatically quit printer app once the print jobs complete
        defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

        # Disable Notification Center and remove the menu bar icon
        launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null

        ###############################################################
        # Trackpad, mouse, keyboard, Bluetooth accessories, and input #
        ###############################################################
        # Shows battery percentage
        defaults write com.apple.menuextra.battery ShowPercent YES; killall SystemUIServer

        # Increase sound quality for Bluetooth headphones/headsets
        defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

        # Follow the keyboard focus while zoomed in
        defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

        # Show language menu in the top right corner of the boot screen
        sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool true

        # Set language and text formats
        # Note: if you’re in the US, replace `EUR` with `USD`, `Centimeters` with
        # `Inches`, `en_GB` with `en_US`, and `true` with `false`.
        defaults write NSGlobalDomain AppleLanguages -array "en"
        defaults write NSGlobalDomain AppleLocale -string "en_GB@currency=GBP"
        defaults write NSGlobalDomain AppleMeasurementUnits -string "Inches"
        defaults write NSGlobalDomain AppleMetricUnits -bool true
        
        # Stop iTunes from responding to the keyboard media keys
        launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist 2>/dev/null

        ##########
        # Screen #
        ##########
        # Require password immediately after sleep or screen saver begins
        defaults write com.apple.screensaver askForPassword -int 1
        defaults write com.apple.screensaver askForPasswordDelay -int 0

        # Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
        defaults write com.apple.screencapture type -string "png"

        # Disable shadow in screenshots
        defaults write com.apple.screencapture disable-shadow -bool true

        ###############################################################################
        # Google Chrome & Google Chrome Canary                                        #
        ###############################################################################
        # Disable the all too sensitive backswipe on trackpads
        defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false
        defaults write com.google.Chrome.canary AppleEnableSwipeNavigateWithScrolls -bool false

        # Disable the all too sensitive backswipe on Magic Mouse
        defaults write com.google.Chrome AppleEnableMouseSwipeNavigateWithScrolls -bool false
        defaults write com.google.Chrome.canary AppleEnableMouseSwipeNavigateWithScrolls -bool false

        # Use the system-native print preview dialog
        defaults write com.google.Chrome DisablePrintPreview -bool true
        defaults write com.google.Chrome.canary DisablePrintPreview -bool true

        # Expand the print dialog by default
        defaults write com.google.Chrome PMPrintingExpandedStateForPrint2 -bool true
        defaults write com.google.Chrome.canary PMPrintingExpandedStateForPrint2 -bool true

      ###############################################################################
      # Mail                                                                        #
      ###############################################################################
      # Disable send and reply animations in Mail.app
      defaults write com.apple.mail DisableReplyAnimations -bool true
      defaults write com.apple.mail DisableSendAnimations -bool true
      # Copy email addresses as `foo@example.com` instead of `Foo Bar <foo@example.com>` in Mail.app
      defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
      # Add the keyboard shortcut ⌘ + Enter to send an email in Mail.app
      defaults write com.apple.mail NSUserKeyEquivalents -dict-add "Send" "@\U21a9"
      # Display emails in threaded mode, sorted by date (oldest at the top)
      defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
      defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending" -string "yes"
      defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder" -string "received-date"
      # Disable inline attachments (just show the icons)
      defaults write com.apple.mail DisableInlineAttachmentViewing -bool true
      # Disable automatic spell checking
      defaults write com.apple.mail SpellCheckingBehavior -string "NoSpellCheckingEnabled"
      '';
    };

  };
}
