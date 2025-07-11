{ pkgs, theme, lib, inputs, ... }:

let
  hostName = "theory";
in
{
  imports = [
    ./hardware-configuration.nix
    # Unmigrated roles (still need manual imports)
    ../../modules/nixos/roles/multimedia.nix
  ];

  services = {
    openssh.enable = true;
    openssh.settings.PasswordAuthentication = true;

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = [ "--ssh" ];
    };

    greetd.enable = true;

    actkbd = {
      enable = true;
      bindings = [
        { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 10"; }
        { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 10"; }
      ];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    xdgOpenUsePortal = true;
    config.common.default = "*";
  };

  programs = {
    hyprland.enable = true;
    regreet.enable = true;
  };

  stylix = {
    enable = true;
    polarity = "dark";

    base16Scheme = "${inputs.nightfox}/extra/nightfox/base16.yaml";

    targets.gtk.enable = true;

    image = ../../wallpapers/nightfox.jpg;

    fonts = {
      serif = {
        package = pkgs.pragmatapro;
        name = "PragmataPro";
      };

      sansSerif = {
        package = pkgs.pragmatapro;
        name = "PragmataPro";
      };

      monospace = {
        package = pkgs.pragmatapro;
        name = "PragmataPro Mono";
      };

      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
  };

  modules.nixos.roles.desktop.enable = true;
}
