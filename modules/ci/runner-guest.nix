{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  runner = config.services.github-runners.nix-ci;
  secondaryRepo = config.modules.ci.secondaryRunnerRepository;
  secondary = config.services.github-runners.nix-ci-secondary or { enable = false; };
  secondaryUser = "dotfiles-ci-secondary";
  guestName = config.networking.hostName;
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../nixos/roles/ci.nix
  ];

  options.modules.ci.secondaryRunnerRepository = lib.mkOption {
    type = lib.types.nullOr (lib.types.strMatching "[A-Za-z0-9-]+/[A-Za-z0-9_.-]+");
    default = null;
    description = "A second private GitHub repository (owner/repo) served by this guest.";
  };

  config = {

    modules.ci.binaryCache =
      lib.mkIf (runner.enable || secondary.enable)
        (import ./tailnet-caches.nix).modules.ci.binaryCache;

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
    users.allowNoPasswordLogin = !(runner.enable || secondary.enable);

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
    services.github-runners.nix-ci-secondary = lib.mkIf (secondaryRepo != null) {
      enable = true;
      name = "${guestName}-${builtins.baseNameOf secondaryRepo}";
      url = "https://github.com/${secondaryRepo}";
      tokenFile = "/var/lib/dotfiles-ci-registration/secondary-token";
      tokenType = "registration";
      user = secondaryUser;
      group = secondaryUser;
      noDefaultLabels = true;
      inherit (runner) extraLabels extraPackages;
    };

    systemd.services = lib.mkMerge [
      (lib.mkIf runner.enable {
        github-runner-nix-ci = {
          unitConfig.ConditionPathExists = runner.tokenFile;
          environment.GOFLAGS = lib.mkDefault "-modcacherw";
        };
      })
      (lib.mkIf secondary.enable {
        github-runner-nix-ci-secondary = {
          unitConfig.ConditionPathExists = secondary.tokenFile;
          environment.GOFLAGS = lib.mkDefault "-modcacherw";
        };
      })
    ];
    users.groups.dotfiles-ci = { };
    users.users.dotfiles-ci = {
      isSystemUser = true;
      group = "dotfiles-ci";
    };
    users.groups.${secondaryUser} = lib.mkIf secondary.enable { };
    users.users.${secondaryUser} = lib.mkIf secondary.enable {
      isSystemUser = true;
      group = secondaryUser;
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
        ]
        ++ lib.optional secondary.enable secondaryUser;
        sandbox = true;
        max-jobs = 1;
        cores = 0;
        min-free = 2 * 1024 * 1024 * 1024;
        max-free = 6 * 1024 * 1024 * 1024;
      };
      gc = {
        automatic = true;
        options = "--delete-older-than 14d";
      };
    };

    assertions =
      lib.optional (runner.enable || secondary.enable) {
        assertion = config.users.users.root.openssh.authorizedKeys.keys != [ ];
        message = "Set a guest administration SSH public key before enabling a runner on ${guestName}.";
      }
      ++ lib.optional runner.enable {
        assertion =
          runner.url != null
          && builtins.match "https://github[.]com/[A-Za-z0-9-]+(/[A-Za-z0-9_.-]+)?" runner.url != null;
        message = "Set the ${guestName} runner URL to a GitHub repository or organization URL.";
      }
      ++ lib.optional (runner.enable && secondary.enable) {
        assertion = runner.url == null || lib.toLower runner.url != lib.toLower secondary.url;
        message = "The runners on ${guestName} must serve different repositories.";
      };

    system.build.ciImage = import (modulesPath + "/../lib/make-disk-image.nix") {
      inherit config lib pkgs;
      name = "${guestName}-image";
      baseName = guestName;
      partitionTableType = "legacy";
      label = guestName;
      diskSize = 128 * 1024;
      format = "qcow2";
    };
  };
}
