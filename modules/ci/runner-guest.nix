{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  runner = config.services.github-runners.nix-ci;
  guestName = config.networking.hostName;
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../nixos/roles/ci.nix
  ];

  modules.ci.binaryCache = lib.mkIf runner.enable (import ./tailnet-caches.nix)
  .modules.ci.binaryCache;

  nixpkgs.hostPlatform = "x86_64-linux";
  system.stateVersion = "25.11";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.kernelParams = [
    "console=ttyS0"
    "net.ifnames=0"
  ];
  fileSystems."/" = {
    device = "/dev/disk/by-label/${guestName}";
    fsType = "ext4";
  };

  networking = {
    enableIPv6 = false;
    useDHCP = false;
    interfaces.eth0.ipv4.addresses = [
      {
        address = "192.168.186.2";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.186.1";
    nameservers = [
      "9.9.9.9"
      "149.112.112.112"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      AllowUsers = [ "root" ];
      DisableForwarding = true;
    };
  };
  users.mutableUsers = false;
  # Allow building the unenrolled image without a login; never enable password authentication.
  users.allowNoPasswordLogin = !runner.enable;

  services.github-runners.nix-ci = {
    name = config.networking.hostName;
    tokenFile = "/var/lib/dotfiles-ci-registration/token";
    tokenType = "registration";
    user = "dotfiles-ci";
    group = "dotfiles-ci";
    extraLabels = [
      "nix"
      "nixos"
      "isolated-ci"
      guestName
    ];
    extraPackages = [
      config.nix.package
      pkgs.attic-client
      pkgs.jq
    ];
  };
  systemd.services.github-runner-nix-ci.unitConfig.ConditionPathExists =
    lib.mkIf runner.enable runner.tokenFile;
  users.groups.dotfiles-ci = { };
  users.users.dotfiles-ci = {
    isSystemUser = true;
    group = "dotfiles-ci";
  };

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      allowed-users = [
        "root"
        "dotfiles-ci"
      ];
      sandbox = true;
      max-jobs = 2;
      cores = 2;
      min-free = 2 * 1024 * 1024 * 1024;
      max-free = 6 * 1024 * 1024 * 1024;
    };
    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
  };

  assertions = lib.optionals runner.enable [
    {
      assertion = config.users.users.root.openssh.authorizedKeys.keys != [ ];
      message = "Set a guest administration SSH public key before enabling the ${guestName} runner.";
    }
    {
      assertion =
        runner.url != null
        && builtins.match "https://github[.]com/[A-Za-z0-9-]+(/[A-Za-z0-9_.-]+)?" runner.url != null;
      message = "Set the ${guestName} runner URL to a GitHub repository or organization URL.";
    }
  ];

  system.build.ciImage = import (modulesPath + "/../lib/make-disk-image.nix") {
    inherit config lib pkgs;
    name = "${guestName}-image";
    baseName = guestName;
    partitionTableType = "legacy";
    label = guestName;
    diskSize = 32768;
    format = "qcow2";
  };
}
