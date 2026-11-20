{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.nixos.roles.ci-vm;
  name = "${config.networking.hostName}-ci";
  inherit (config.modules.ci) attic;
  proxyPort = 8443;
  localAddress = "192.168.186.1";
  peerAddress = "192.168.187.1";
  relays =
    lib.optionalAttrs attic.enable {
      "${name}-attic" = {
        address = localAddress;
        port = attic.httpsPort;
        target = "127.0.0.1:${toString proxyPort}";
        services = [
          "caddy.service"
          "atticd.service"
        ];
      };
    }
    // lib.optionalAttrs (cfg.cacheRelayAddress != null) {
      "${name}-attic-peer" = {
        address = peerAddress;
        port = cfg.cacheRelayPort;
        target = "${cfg.cacheRelayAddress}:${toString cfg.cacheRelayPort}";
        services = [ "tailscaled.service" ];
      };
    };
  guardRules = pkgs.writeText "${name}.nft" (
    builtins.readFile ./ci-vm.nft
    + lib.concatMapStrings (relay: ''
      add element inet dotfiles_ci attic_endpoints { ${relay.address} . ${toString relay.port} }
    '') (builtins.attrValues relays)
  );
  uid = toString config.ids.uids.qemu-libvirtd;
  gid = toString config.ids.gids.qemu-libvirtd;
  guard =
    phase:
    pkgs.writeShellScript "${name}-guard-${phase}" ''
      if [[ "$1" == ${name} && "$2" == ${phase} && "$3" == begin ]]; then
        exec ${pkgs.nftables}/bin/nft -f ${guardRules}
      fi
    '';
in
{
  options.modules.nixos.roles.ci-vm = {
    enable = lib.mkEnableOption "a dedicated libvirt VM for CI";
    vcpus = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4;
      description = "Number of virtual CPUs scheduled on the host without pinning.";
    };
    memoryMiB = lib.mkOption {
      type = lib.types.ints.positive;
      default = 8192;
      description = "Guest RAM in MiB; unused pages can be returned to the host.";
    };
    cacheRelayAddress = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.strMatching "100[.](6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])[.]([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])[.]([0-9]{1,2}|1[0-9]{2}|2[0-4][0-9]|25[0-5])"
      );
      default = null;
      description = "Tailscale IPv4 of the remote Attic HTTPS server.";
    };
    cacheRelayPort = lib.mkOption {
      type = lib.types.ints.between 1 65535;
      default = 443;
      description = "HTTPS port of the remote Attic server and its CI guest relay.";
    };
  };

  config = lib.mkIf cfg.enable {
    security.polkit.enable = true;
    virtualisation.libvirtd.enable = true;
    virtualisation.libvirtd.qemu.runAsRoot = lib.mkDefault false;
    virtualisation.libvirtd.hooks = {
      network."${name}-guard" = guard "start";
      qemu."${name}-guard" = guard "prepare";
    };

    services.caddy = lib.mkIf attic.enable {
      globalConfig = lib.mkAfter ''
        pki {
          ca ${name}-attic {
            name "${name} Attic"
          }
        }
      '';
      virtualHosts."https://${attic.hostname}:${toString proxyPort}".extraConfig = ''
        bind 127.0.0.1
        tls {
          issuer internal {
            ca ${name}-attic
          }
        }
        reverse_proxy 127.0.0.1:${toString attic.port}
      '';
    };

    # FreeBind lets the upload socket start before libvirt creates the bridge.
    systemd.sockets = lib.mapAttrs (_: relay: {
      wantedBy = [ "sockets.target" ];
      socketConfig = {
        ListenStream = "${relay.address}:${toString relay.port}";
        FreeBind = true;
      };
    }) relays;

    systemd.services = lib.mapAttrs (_: relay: {
      wants = relay.services;
      after = relay.services;
      serviceConfig = {
        ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd ${relay.target}";
        DynamicUser = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
      };
    }) relays;

    networking.firewall.interfaces.virbr-ci.allowedTCPPorts = lib.unique (
      map (relay: relay.port) (builtins.attrValues relays)
    );

    environment.etc."libvirt/${name}-nft".source = "${pkgs.nftables}/bin/nft";
    environment.etc."libvirt/${name}.nft".source = guardRules;

    environment.etc."libvirt/${name}-network.xml".text = ''
      <network>
        <name>${name}</name>
        <forward mode='nat'/>
        <bridge name='virbr-ci' stp='off' delay='0'/>
        <dns enable='no'/>
        <ip address='${localAddress}' prefix='24'/>
        ${lib.optionalString (cfg.cacheRelayAddress != null) "<ip address='${peerAddress}' prefix='30'/>"}
      </network>
    '';

    environment.etc."libvirt/${name}-domain.xml".text = ''
      <domain type='kvm'>
        <name>${name}</name>
        <memory unit='MiB'>${toString cfg.memoryMiB}</memory>
        <vcpu>${toString cfg.vcpus}</vcpu>
        <os>
          <type arch='x86_64' machine='q35'>hvm</type>
          <boot dev='hd'/>
        </os>
        <features><acpi/><apic/></features>
        <cpu mode='host-model'/>
        <devices>
          <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
          <disk type='file' device='disk'>
            <driver name='qemu' type='qcow2' discard='unmap'/>
            <source file='/var/lib/libvirt/images/${name}.qcow2'/>
            <target dev='vda' bus='virtio'/>
          </disk>
          <interface type='network'>
            <source network='${name}'/>
            <model type='virtio'/>
          </interface>
          <console type='pty'/>
          <memballoon model='virtio' freePageReporting='on'/>
        </devices>
        <seclabel type='static' model='dac' relabel='yes'>
          <label>+${uid}:+${gid}</label>
        </seclabel>
      </domain>
    '';
  };
}
