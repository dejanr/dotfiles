{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    qemu # A generic and open source machine emulator and virtualizer
    virtmanager # Desktop user interface for managing virtual machines
    vde2 # Virtual Distributed Ethernet, an Ethernet compliant virtual network
    pciutils # A collection of programs for inspecting and manipulating configuration of PCI devices
    OVMF # Sample UEFI firmware for QEMU and KVM
    seabios # Open source implementation of a 16bit X86 BIOS
    libguestfs # Tools for accessing and modifying virtual machine disk images
    libguestfs # Tools for accessing and modifying virtual machine disk images
    libvirt # A toolkit to interact with the virtualization capabilities of recent versions of Linux (and other OSes)
    virt-viewer # A viewer for remote virtual machines
    bridge-utils
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemuOvmf = true;
    qemuRunAsRoot = false;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };
  users.groups.libvirtd.members = [ "root" "dejanr" ];
  users.extraUsers.dejanr.extraGroups = [ "libvirtd" ];
  networking.firewall.checkReversePath = false;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
    storageDriver = "zfs";
  };

  virtualisation.lxd.zfsSupport = true;
}
