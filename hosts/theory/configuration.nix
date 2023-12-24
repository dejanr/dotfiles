{ pkgs , lib , ... }:

let
    hostName = "theory";
in
{
    imports = [
        ../../modules/system/roles/fonts.nix
        ../../modules/system/roles/desktop.nix
        ../../modules/system/roles/multimedia.nix
        ../../modules/system/roles/i3.nix
    ];

    services = {
        openssh.enable = true;
        openssh.settings.PasswordAuthentication = true;

        xserver = {
            enable = true;
            dpi = 254;

            displayManager = {
                xserverArgs = [ "-dpi 254" ];
            };
        };

        tailscale = {
            enable = true;
            useRoutingFeatures = "both";
            extraUpFlags = ["--ssh"];
        };
    };

    environment = {
    etc."X11/Xresources".text = ''
        Xft.dpi: 254
    '';
    systemPackages = [ ];
    };

    programs.light.enable = true;
    services.actkbd = {
        enable = true;
        bindings = [
            { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 10"; }
            { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 10"; }
        ];
    };
 }
