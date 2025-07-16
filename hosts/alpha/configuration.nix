{ pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  environment.systemPackages = with pkgs; [
    qemu # A generic and open source machine emulator and virtualizer
    vde2 # Virtual Distributed Ethernet, an Ethernet compliant virtual network
    pciutils # A collection of programs for inspecting and manipulating configuration of PCI devices
    OVMF # Sample UEFI firmware for QEMU and KVM
    seabios # Open source implementation of a 16bit X86 BIOS
    libguestfs # Tools for accessing and modifying virtual machine disk images
    libvirt # A toolkit to interact with the virtualization capabilities of recent versions of Linux (and other OSes)
    bridge-utils # An userspace tool to configure linux bridges (deprecated in favour or iproute2).
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
    qemu.runAsRoot = true;
    onBoot = "start";
    onShutdown = "shutdown";
    allowedBridges = [ "br0" ];
  };

  users.groups.libvirtd.members = [
    "root"
    "dejanr"
  ];
  users.extraUsers.dejanr.extraGroups = [ "libvirtd" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

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
}
