{ pkgs , lib , ... }:

{
  imports = [
    ../../modules/system/roles/common.nix
    ../../modules/system/roles/services.nix
  ];

  environment.systemPackages = with pkgs; [
    qemu # A generic and open source machine emulator and virtualizer
    vde2 # Virtual Distributed Ethernet, an Ethernet compliant virtual network
    pciutils # A collection of programs for inspecting and manipulating configuration of PCI devices
    OVMF # Sample UEFI firmware for QEMU and KVM
    seabios # Open source implementation of a 16bit X86 BIOS
    libguestfs # Tools for accessing and modifying virtual machine disk images
    libvirt # A toolkit to interact with the virtualization capabilities of recent versions of Linux (and other OSes)
    bridge-utils
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
    qemu.runAsRoot = true;
    onBoot = "start";
    onShutdown = "shutdown";
    allowedBridges = [ "br0" ];
  };

  systemd.tmpfiles.rules = [
    "f /dev/shm/scream 0660 dejanr qemu-libvirtd -"
    "f /dev/shm/looking-glass 0660 dejanr qemu-libvirtd -"
  ];

  users.groups.libvirtd.members = [ "root" "dejanr" ];
  users.extraUsers.dejanr.extraGroups = [ "libvirtd" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  system.stateVersion = "23.05";
}
