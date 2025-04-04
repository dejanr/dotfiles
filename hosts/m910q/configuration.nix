{ pkgs, lib, inputs, ... }:

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
    tempAddresses = "disabled";
    nftables.enable = true;
    firewall.enable = false;
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
    extraGroups = [ "wheel" "incus-admin" ];
    openssh.authorizedKeys.keyFiles = [
      inputs.ssh-keys.outPath
    ];
  };

  services = { };
}
