{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    ../../modules/darwin/ci-runner.nix
    ../../modules/darwin/ci-tailnet.nix
  ];

  system.primaryUser = "dejanr";
  system.stateVersion = 6;
  power.sleep.computer = "never";
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.activationScripts.preActivation.text = ''
    case "$(/usr/sbin/sysctl -n hw.model)" in
      VirtualMac*) ;;
      *) echo 'The mbp-work-ci configuration is only for a macOS virtual machine.' >&2; exit 1 ;;
    esac
  '';

  networking = {
    hostName = "mbp-work-ci";
    knownNetworkServices = [ "Ethernet" ];
    dns = [
      "9.9.9.9"
      "149.112.112.112"
    ];
  };

  modules.darwin.ci-tailnet = {
    enable = true;
    authorizedKeysFile = inputs.ssh-keys.outPath;
  };

  nix.enable = false;
  environment.etc."nix/dotfiles-ci.conf".text = ''
    experimental-features = nix-command flakes
    allowed-users = root ${config.system.primaryUser} _dotfilesci
    trusted-users = root
    max-jobs = 1
    cores = 0
  '';

  environment.systemPackages = [ pkgs.git ];

  modules.darwin.ci-runner = {
    enable = true;
    url = "https://github.com/dejli/draw";
  };
}
