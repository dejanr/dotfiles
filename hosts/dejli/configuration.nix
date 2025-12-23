{
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Enable x86_64 emulation for cross-platform builds
  boot.binfmt.emulatedSystems = [ "x86_64-linux" ];

  virtualisation.podman.enable = true;

  # sst.dev
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    bun
  ];
  programs.mosh.enable = true;

  programs.ssh.extraConfig = '''';

  modules.nixos = {
    roles = {
      hosts.enable = true;
      dev.enable = true;
      i3.enable = true;
      desktop.enable = true;
      multimedia.enable = true;
      services.enable = true;
    };
  };
}
