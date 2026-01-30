{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./apple-silicon-support
  ];

  services = {
    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "both";
      extraUpFlags = [ "--ssh" ];
      extraSetFlags = [ "--advertise-exit-node" ];
    };
  };

  # Asahi HDMI fix: wait for DCP to initialize before starting X
  # The display controller needs time to properly initialize HDMI output
  services.xserver.displayManager.setupCommands = ''
    # Wait for DCP display initialization on Asahi
    # Check for connected displays, retry if none found
    for i in $(seq 1 10); do
      if ${pkgs.xorg.xrandr}/bin/xrandr | grep -q " connected"; then
        break
      fi
      sleep 1
    done
    ${pkgs.xorg.xrandr}/bin/xrandr --auto || true
  '';

  # Disable DPMS and screen blanking - Asahi HDMI doesn't wake reliably
  services.xserver.displayManager.sessionCommands = ''
    ${pkgs.xorg.xset}/bin/xset s off
    ${pkgs.xorg.xset}/bin/xset -dpms
    ${pkgs.xorg.xset}/bin/xset s noblank
  '';

  # Delay display-manager start to allow DCP initialization
  systemd.services.display-manager = {
    after = [ "systemd-udev-settle.service" ];
    wants = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 3";
    };
  };

  # === SYSTEM PERFORMANCE TWEAKS ===

  # Use zram for swap (faster than disk swap, good for Apple SSDs)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # Kernel tweaks for responsiveness
  boot.kernel.sysctl = {
    # Reduce swap tendency (0-200, lower = less swap)
    "vm.swappiness" = 10;
    # Better for SSDs
    "vm.vfs_cache_pressure" = 50;
    # Network performance
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    # Faster process forking
    "kernel.sched_child_runs_first" = 1;
  };

  # Faster boot: don't wait for network
  systemd.services.NetworkManager-wait-online.enable = false;

  # Enable earlyoom to prevent system freeze on low memory
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 5;
    freeSwapThreshold = 10;
  };

  # Trim SSD weekly
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  modules.nixos = {
    roles = {
      hosts.enable = true;
      dev.enable = true;
      i3.enable = true;
      desktop = {
        enable = true;
        # OLED TV font rendering - no subpixel, full hinting
        fontconfig = {
          hinting.style = "full";
          subpixel.rgba = "none";
          subpixel.lcdfilter = "none";
        };
      };
      games.enable = true;
      multimedia.enable = true;
      services.enable = true;
      #virtualisation.enable = true;
    };
  };
}
