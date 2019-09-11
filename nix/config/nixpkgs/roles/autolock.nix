{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    wm-lock
    xautolock                    # suckless xautolock
    xss-lock                     # screensaver
  ];

  services.xserver.displayManager.sessionCommands = with pkgs; lib.mkAfter
  ''
    ${pkgs.xautolock}/bin/xautolock -time 15 -locker ${wm-lock}/bin/wm-lock &
  '';
}
