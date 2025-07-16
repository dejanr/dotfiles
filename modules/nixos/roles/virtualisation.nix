{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.modules.nixos.roles.virtualisation;

in
{
  options.modules.nixos.roles.virtualisation = {
    enable = mkEnableOption "virtualisation system integration";
  };

  config = mkIf cfg.enable {
    # Add shared memory device for kvm machine
    #
    #<shmem name='looking-glass'>
    #  <model type='ivshmem-plain'/>
    #  <size unit='M'>64</size>
    #</shmem>
    #
    environment.systemPackages = with pkgs; [
      looking-glass-client
      qemu # A generic and open source machine emulator and virtualizer
      virt-manager # Desktop user interface for managing virtual machines
      vde2 # Virtual Distributed Ethernet, an Ethernet compliant virtual network
      pciutils # A collection of programs for inspecting and manipulating configuration of PCI devices
      OVMF # Sample UEFI firmware for QEMU and KVM
      seabios # Open source implementation of a 16bit X86 BIOS
      libguestfs # Tools for accessing and modifying virtual machine disk images
      libvirt # A toolkit to interact with the virtualization capabilities of recent versions of Linux (and other OSes)
      virt-viewer # A viewer for remote virtual machines
      bridge-utils
    ];

    virtualisation.podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };

    virtualisation.libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
      qemu.runAsRoot = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      allowedBridges = [ "br0" ];
    };

    systemd.tmpfiles.rules = [
      "f /dev/shm/scream 0660 dejanr qemu-libvirtd -"
      "f /dev/shm/looking-glass 0660 dejanr qemu-libvirtd -"
    ];

    # TODO: Use a hook so that it starts only *after* the shmem device is initialized
    systemd.user.services.scream-ivshmem = {
      enable = true;
      description = "Scream IVSHMEM";
      serviceConfig = {
        ExecStart = "${pkgs.scream}/bin/scream-ivshmem-pulse /dev/shm/scream";
        Restart = "always";
      };
      wantedBy = [ "multi-user.target" ];
      requires = [ "pulseaudio.service" ];
    };

    users.groups.libvirtd.members = [
      "root"
      "dejanr"
    ];
    users.extraUsers.dejanr.extraGroups = [ "libvirtd" ];

    virtualisation.spiceUSBRedirection.enable = true;
  };
}
