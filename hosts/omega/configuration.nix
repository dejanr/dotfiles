{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  services.ollama = {
    enable = true;
    acceleration = "cuda";
  };

  virtualisation.podman.enable = true;

  # sst.dev
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    bun
  ];

  modules.nixos = {
    theme.enable = true;
    theme.flavor = "mocha";

    roles = {
      desktop.enable = true;
      dev.enable = true;
      games.enable = true;
      hosts.enable = true;
      sway.enable = true;
      multimedia.enable = true;
      services.enable = true;
      virtualisation.enable = true;
    };

    services.openvpn.office = {
      enable = true;
      username = "dejanr";
    };
  };
}
