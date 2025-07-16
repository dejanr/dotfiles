{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  hostConfigs = {
    m910q1 = {
      incus.preseed = {
        config = {
          core.https_address = "192.168.1.111:8443";
        };
        cluster = {
          server_name = "m910q1";
          enabled = true;
        };
      };
    };
    m910q2 = {
      incus.preseed = {
        config = { };
        cluster = {
          enabled = true;
          server_name = "m910q2";
          cluster_address = "192.168.1.111:8443";
          server_address = "192.168.1.112:8443";
        };
      };
    };
    m910q3 = {
      incus.preseed = {
        config = { };
        cluster = {
          enabled = true;
          server_name = "m910q3";
          cluster_address = "192.168.1.111:8443";
          server_address = "192.168.1.113:8443";
        };
      };
    };
    m910q4 = {
      incus.preseed = {
        config = { };
        cluster = {
          enabled = true;
          server_name = "m910q4";
          cluster_address = "192.168.1.111:8443";
          server_address = "192.168.1.114:8443";
        };
      };
    };
  };

  hostConfig = hostConfigs.${config.networking.hostName} or { };
in
{
  imports = [
    ./disk-config.nix
  ];

  environment.systemPackages = with pkgs; [
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ ];
  boot.extraModprobeConfig = ''
    options kvm ignore_msrs=1 report_ignored_msrs=0
  '';

  # Networking
  networking = {
    firewall = {
      enable = false;
      interfaces.externalbr0.allowedTCPPorts = [
        53
        67
      ];
      interfaces.externalbr0.allowedUDPPorts = [
        53
        67
      ];
      trustedInterfaces = [ "externalbr0" ];
    };
    tempAddresses = "disabled";
    nftables.enable = true;
    useDHCP = false;
    bridges = {
      externalbr0 = {
        interfaces = [ "enp0s31f6" ];
      };
    };
    interfaces = {
      externalbr0 = {
        useDHCP = true;
      };
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  time.timeZone = "Europe/Berlin";
  console.keyMap = "us";
  i18n.defaultLocale = "en_US.UTF-8";
  system.autoUpgrade = {
    enable = true;
    dates = "weekly";
    allowReboot = true;
  };

  services = {
    fail2ban = {
      enable = true;
      jails = {
        # this is predefined
        ssh-iptables = ''
          enabled  = true
        '';
      };
    };

    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
      settings.PasswordAuthentication = false;
    };

    tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      extraUpFlags = [ "--ssh" ];
    };

    postfix = {
      enable = true;
      setSendmail = true;
    };
  };

  virtualisation = {
    kvmgt.enable = true;
    incus = {
      enable = true;
      ui.enable = true;
      package = pkgs.incus;
      preseed = {
        config = hostConfig.incus.preseed.config;
        cluster = hostConfig.incus.preseed.cluster;
        networks = [
          {
            name = "internalbr0";
            type = "bridge";
            description = "Internal/NATted bridge";
            config = {
              "ipv4.address" = "auto";
              "ipv4.nat" = "true";
              "ipv6.address" = "auto";
              "ipv6.nat" = "true";
            };
          }
        ];
        profiles = [
          {
            name = "default";
            description = "Default Incus Profile";
            devices = {
              eth0 = {
                name = "eth0";
                network = "internalbr0";
                type = "nic";
              };
              root = {
                path = "/";
                pool = "default";
                type = "disk";
              };
            };
          }
          {
            name = "bridged";
            description = "Instances bridged to LAN";
            devices = {
              eth0 = {
                name = "eth0";
                nictype = "bridged";
                parent = "externalbr0";
                type = "nic";
              };
              root = {
                path = "/";
                pool = "default";
                type = "disk";
              };
            };
          }
        ];
        storage_pools = [
          {
            config = {
              source = "/var/lib/incus/storage-pools/default";
            };
            driver = "dir";
            name = "default";
          }
        ];
      };
    };
  };

  # Users. Don't forget to set a password with "passwd"!
  users.users.dejanr = {
    isNormalUser = true;
    description = "Dejan Ranisavljevic";
    extraGroups = [
      "wheel"
      "incus-admin"
    ];
    openssh.authorizedKeys.keyFiles = [
      inputs.ssh-keys.outPath
    ];
  };

  services = { };
}
