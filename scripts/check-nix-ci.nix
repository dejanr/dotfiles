flake:
let
  inherit (flake.inputs.nixpkgs) lib;
  caches = (import ../modules/ci/tailnet-caches.nix).modules.ci.binaryCache.caches;
  expectedSubstituters = map (cache: "${cache.url}?priority=${toString cache.priority}") caches;
  expectedKeys = map (cache: cache.publicKey) caches;
  checkClient =
    settings:
    settings.extra-substituters == expectedSubstituters
    && settings.extra-trusted-public-keys == expectedKeys
    && settings.fallback
    && !(settings ? netrc-file);
  cacheHost = flake.nixosConfigurations.omega.config;
  framework = flake.nixosConfigurations.framework;
  frameworkClient =
    (framework.extendModules {
      modules = [
        {
          modules.ci.attic.enable = lib.mkForce false;
          modules.nixos.roles.ci-vm.enable = lib.mkForce false;
        }
      ];
    }).config;
  frameworkWithVM = framework.config;
  mac = flake.darwinConfigurations.M-G1997RD02K.config;
  macCacheSettings = mac.environment.etc."nix/dotfiles-ci.conf".text;
  omegaGuest = flake.nixosConfigurations.omega-ci;
  frameworkGuest = flake.nixosConfigurations.framework-ci;
  enableGuest =
    guest:
    (guest.extendModules {
      modules = [
        {
          services.github-runners.nix-ci = {
            enable = true;
            url = "https://github.com/example/private-ci";
          };
          users.users.root.openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICZ8YEjZ6ApwfxKiOmLlJyUJWJWh06vC55iWmVAWSXGz test-only"
          ];
        }
      ];
    }).config;
  activeGuest = enableGuest omegaGuest;
  activeFrameworkGuest = enableGuest frameworkGuest;
  runner = activeGuest.services.github-runners.nix-ci;
  attic = cacheHost.services.atticd;
  proxy = cacheHost.services.caddy.virtualHosts."https://omega.cat-vimba.ts.net:8443".extraConfig;
  checkResources =
    host: memoryMiB:
    let
      domain = host.environment.etc."libvirt/${host.networking.hostName}-ci-domain.xml".text;
    in
    lib.hasInfix "<memory unit='MiB'>${toString memoryMiB}</memory>" domain
    && lib.hasInfix "<vcpu>32</vcpu>" domain
    && lib.hasInfix "<memballoon model='virtio' freePageReporting='on'/>" domain
    && !(lib.hasInfix "<vcpupin" domain);
in
assert cacheHost.services.github-runners == { } && frameworkWithVM.services.github-runners == { };
assert
  map (cache: cache.priority) caches == [
    41
    42
  ];
assert lib.all checkClient [
  frameworkClient.nix.settings
  cacheHost.nix.settings
  activeFrameworkGuest.nix.settings
  activeGuest.nix.settings
];
assert !frameworkClient.services.atticd.enable;
assert !(builtins.hasAttr "framework-ci-attic" frameworkClient.systemd.sockets);
assert checkResources frameworkWithVM 65536;
assert checkResources cacheHost 32768;
assert frameworkWithVM.virtualisation.libvirtd.enable;
assert !frameworkWithVM.virtualisation.libvirtd.qemu.runAsRoot;
assert frameworkWithVM.services.atticd.enable;
assert frameworkWithVM.services.atticd.environmentFile == "/run/agenix/attic_server";
assert
  builtins.baseNameOf (toString frameworkWithVM.age.secrets.attic_server.file)
  == "attic_framework_server.age";
assert frameworkWithVM.age.secrets.attic_server.mode == "0400";
assert !(builtins.hasAttr "attic_server" frameworkClient.age.secrets);
assert
  frameworkWithVM.services.atticd.settings.api-endpoint == "https://framework.cat-vimba.ts.net:8444/";
assert builtins.elem "framework.cat-vimba.ts.net:8444"
  frameworkWithVM.services.atticd.settings.allowed-hosts;
assert
  frameworkWithVM.systemd.sockets.framework-ci-attic.socketConfig.ListenStream
  == "192.168.186.1:8444";
assert
  frameworkWithVM.systemd.sockets.framework-ci-attic-peer.socketConfig.ListenStream
  == "192.168.187.1:8444";
assert lib.hasSuffix "systemd-socket-proxyd 100.76.1.33:8444"
  frameworkWithVM.systemd.services.framework-ci-attic-peer.serviceConfig.ExecStart;
assert lib.hasInfix "<ip address='192.168.187.1' prefix='30'/>"
  frameworkWithVM.environment.etc."libvirt/framework-ci-network.xml".text;
assert lib.hasInfix "ca framework-ci-attic"
  frameworkWithVM.services.caddy.virtualHosts."https://framework.cat-vimba.ts.net:8443".extraConfig;
assert frameworkWithVM.networking.firewall.interfaces.virbr-ci.allowedTCPPorts == [ 8444 ];
assert builtins.hasAttr "framework-ci-guard" frameworkWithVM.virtualisation.libvirtd.hooks.network;
assert builtins.hasAttr "framework-ci-guard" frameworkWithVM.virtualisation.libvirtd.hooks.qemu;
assert !builtins.elem "dotfiles-ci" cacheHost.nix.settings.allowed-users;
assert !builtins.hasAttr "dotfiles-nix-ci" mac.launchd.daemons;
assert !mac.nix.enable;
assert lib.hasInfix "extra-substituters = ${lib.concatStringsSep " " expectedSubstituters}"
  macCacheSettings;
assert lib.hasInfix "extra-trusted-public-keys = ${lib.concatStringsSep " " expectedKeys}"
  macCacheSettings;
assert lib.hasInfix "fallback = true" macCacheSettings;
assert !lib.hasInfix "netrc-file" macCacheSettings;
assert attic.enable && attic.settings.listen == "127.0.0.1:8081";
assert attic.environmentFile == "/run/agenix/attic_server";
assert
  builtins.baseNameOf (toString cacheHost.age.secrets.attic_server.file) == "attic_omega_server.age";
assert cacheHost.age.secrets.attic_server.owner == "root";
assert attic.settings.api-endpoint == "https://omega.cat-vimba.ts.net:8444/";
assert builtins.elem "omega.cat-vimba.ts.net:8444" attic.settings.allowed-hosts;
assert cacheHost.systemd.sockets.omega-ci-attic.socketConfig.ListenStream == "192.168.186.1:8444";
assert cacheHost.systemd.sockets.omega-ci-attic.socketConfig.FreeBind;
assert lib.hasSuffix "systemd-socket-proxyd 100.77.205.71:8444"
  cacheHost.systemd.services.omega-ci-attic-peer.serviceConfig.ExecStart;
assert cacheHost.networking.firewall.interfaces.virbr-ci.allowedTCPPorts == [ 8444 ];
assert lib.hasInfix "bind 127.0.0.1" proxy && lib.hasInfix "reverse_proxy 127.0.0.1:8081" proxy;
assert lib.hasInfix "omega-ci-attic" proxy;
assert builtins.hasAttr "omega-ci-guard" cacheHost.virtualisation.libvirtd.hooks.network;
assert builtins.hasAttr "omega-ci-guard" cacheHost.virtualisation.libvirtd.hooks.qemu;
assert !omegaGuest.config.services.github-runners.nix-ci.enable;
assert !frameworkGuest.config.services.github-runners.nix-ci.enable;
assert activeFrameworkGuest.services.github-runners.nix-ci.name == "framework-ci";
assert builtins.elem "isolated-ci" activeFrameworkGuest.services.github-runners.nix-ci.extraLabels;
assert activeFrameworkGuest.fileSystems."/".device == "/dev/disk/by-label/framework-ci";
assert lib.isDerivation activeFrameworkGuest.system.build.ciImage;
assert builtins.stringLength activeFrameworkGuest.system.build.toplevel.drvPath > 0;
assert runner.enable && runner.name == "omega-ci" && builtins.elem "omega-ci" runner.extraLabels;
assert builtins.elem omegaGuest.pkgs.attic-client runner.extraPackages;
assert builtins.elem "isolated-ci" runner.extraLabels;
assert builtins.elem runner.user activeGuest.nix.settings.allowed-users;
assert !builtins.elem runner.user activeGuest.nix.settings.trusted-users;
assert activeGuest.nix.settings.sandbox;
assert activeGuest.nix.settings.max-jobs == 1 && activeGuest.nix.settings.cores == 0;
assert
  activeFrameworkGuest.nix.settings.max-jobs == 1 && activeFrameworkGuest.nix.settings.cores == 0;
assert !activeGuest.services.openssh.settings.PasswordAuthentication;
assert !activeGuest.virtualisation.docker.enable;
assert lib.isDerivation activeGuest.system.build.ciImage;
assert builtins.stringLength activeGuest.system.build.toplevel.drvPath > 0;
true
