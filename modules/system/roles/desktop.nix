{ pkgs, inputs, ... }:

{
  environment.systemPackages = with pkgs; [
    acpi # Show battery status and other ACPI information
    arandr # manage dispays
    axel # Console downloading program with some features for parallel connections for faster downloading
    blender # 3D Creation/Animation/Publishing System
    caffeine-ng # Status bar application to temporarily inhibit screensaver and sleep mode
    imv # A command line image viewer for tiling window managers
    evince # gnome document viewer
    gimp # Image Manipulation Program
    grobi # Automatically configure monitors/outputs for Xorg via RANDR
    gnupg # encryption
    google-drive-ocamlfuse # FUSE-based file system backed by Google Drive
    inputs.browser-previews.packages.${pkgs.system}.google-chrome-beta # A freeware web browser developed by Google
    firefox # A web browser built from Firefox source tree
    gtypist # typing practice
    hfsprogs # HFS user space utils, for mounting HFS+ osx partitions
    inkscape # vector graphics editor
    kazam # A screencasting program created with design in mind
    keychain # Keychain management tool
    kdePackages.kdenlive
    libnotify # send notifications to a notification daemon
    lm_sensors # Tools for reading hardware sensors
    magic-wormhole # Securely transfer data between computers
    mutt # A small but very powerful text-based mail client
    newsboat # RSS reader
    # openscad # 3D parametric model compiler
    openvpn # A robust and highly flexible tunneling application
    pciutils # lspci and other utils
    pcmanfm # File manager witth GTK+ interface
    pidgin # Multi-protocol instant messaging client
    pidgin-window-merge # merge contacts and message window
    pinentry # gnupg interface to passphrase input
    polkit # A dbus session bus service that is used to bring up authentication dialogs
    powertop # Analyze power consumption on Intel-based laptops
    printrun # 3d printing host software
    purple-plugin-pack # Plugin pack for Pidgin 2.x
    qalculate-gtk # The ultimate desktop calculator
    scrot # screen capturing
    signal-desktop # signal desktop client
    ifwifi
    wpa_supplicant # networking
    # prusa-slicer # G-code generator for 3D printer
    st # Simple Terminal for X from Suckless.org Community
    # surf # suckless browser
    sxiv # image viewer
    termite # A simple VTE-based terminal
    termite.terminfo # terminfo for termite
    tesseract # OCR engine
    telegram-desktop # desktop telegram client
    thunderbird # email client
    transmission_4-gtk
    usbutils # Tools for working with USB devices, such as lsusb
    unrar # Utility for RAR archives
    update-resolv-conf # Script to update your /etc/resolv.conf with DNS settings that come from the received push dhcp-options pciutils # A collection of programs for inspecting and manipulating configuration of PCI devices
    weechat # A fast, light and extensible chat client
    xclip # clipboard
    xdg-utils # Set of cli tools that assist applications integration
    xsel # Command-line program for getting and setting the contents of the X selection
    xsettingsd # Provides settings to X11 applications via the XSETTINGS specification
    zathura # pdf viewer
    #sweethome3d.furniture-editor # Quickly create SH3F files and edit the properties of the 3D models it contain
    #sweethome3d.application # Design and visualize your future home
    #sweethome3d.textures-editor # Easily create SH3T files and edit the properties of the texture images it contain

    # Themes
    arc-icon-theme
    arc-theme
    adwaita-icon-theme

    samba

    xorg.xmodmap

    rmview # Fast live viewer for reMarkable 1 and 2
  ];

  services.blueman.enable = true;
}
