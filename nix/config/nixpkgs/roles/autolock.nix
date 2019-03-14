{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    i3lock-fancy                 # lock session
    xautolock                    # suckless xautolock
    xss-lock                     # screensaver
  ];

  services.xserver.displayManager.sessionCommands = with pkgs; lib.mkAfter
  ''
    ${pkgs.xautolock}/bin/xautolock -time 15 -locker ~/.bin/lock &
  '';
}
