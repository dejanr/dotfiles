{
  pkgs,
  config,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      51413 # transmission
    ];
    allowedUDPPorts = [
      51413 # transmission
    ];
    interfaces.tailscale0.allowedTCPPorts = [
      80 # nginx http
      443 # nginx https
      9091 # transmission rpc
    ];
  };

  programs.dconf.enable = true;

  users.groups.transmission.members = [ "nginx" ];

  services = {
    fail2ban = {
      enable = true;
    };

    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
      settings.PasswordAuthentication = false;
    };

    tailscale = {
      enable = true;
      openFirewall = true;
      useRoutingFeatures = "both";
      extraSetFlags = [ "--advertise-exit-node" ];
    };

    postfix = {
      enable = true;
      setSendmail = true;
    };

    timesyncd.enable = true;
    timesyncd.servers = [
      "1.amazon.pool.ntp.org"
      "2.amazon.pool.ntp.org"
      "3.amazon.pool.ntp.org"
    ];

    transmission = {
      enable = true;
      package = pkgs.transmission_4;
      openRPCPort = false;
      downloadDirPermissions = "755";
      settings = {
        rpc-port = 9091;
        peer-port = 51413;
        download-dir = "/var/lib/transmission/downloads";
        watch-dir = "/var/lib/transmission/incoming";
        trash-original-torrent-files = true;
        incomplete-dir = "/var/lib/transmission/incomplete";
        incomplete-dir-enabled = true;
        rpc-authentication-required = false;
        rpc-whitelist-enabled = true;
        rpc-whitelist = "127.0.0.1";
        rpc-host-whitelist = "zima.cat-vimba.ts.net";
        rpc-bind-address = "127.0.0.1";
        rpc-enable = true;
      };
    };
    nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      virtualHosts."zima.cat-vimba.ts.net" = {
        root = "/var/lib/transmission/downloads";
        forceSSL = true;
        sslCertificate = "/var/lib/nginx/certs/zima.cat-vimba.ts.net.crt";
        sslCertificateKey = "/var/lib/nginx/certs/zima.cat-vimba.ts.net.key";
        locations."/" = {
          extraConfig = ''
            autoindex on;
            autoindex_exact_size off;
            autoindex_localtime on;
          '';
        };
        locations."/transmission" = {
          proxyPass = "http://127.0.0.1:9091";
          extraConfig = ''
            proxy_pass_header X-Transmission-Session-Id;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
  };

  systemd.services.nginx-copy-certs = {
    description = "Renew Tailscale certificate for nginx";
    wants = [
      "network-online.target"
      "tailscaled.service"
    ];
    after = [
      "network-online.target"
      "tailscaled.service"
    ];
    before = [ "nginx.service" ];
    wantedBy = [ "multi-user.target" ];
    startAt = "daily";
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
      TimeoutStartSec = "2min";
      ExecStartPost = "${pkgs.systemd}/bin/systemctl --no-block try-reload-or-restart nginx.service";
    };
    script = ''
      mkdir -p /var/lib/nginx/certs
      ${config.services.tailscale.package}/bin/tailscale cert \
        --min-validity=720h \
        --cert-file=/var/lib/nginx/certs/zima.cat-vimba.ts.net.crt \
        --key-file=/var/lib/nginx/certs/zima.cat-vimba.ts.net.key \
        zima.cat-vimba.ts.net
      chown nginx:nginx /var/lib/nginx/certs/zima.cat-vimba.ts.net.{crt,key}
      chmod 600 /var/lib/nginx/certs/zima.cat-vimba.ts.net.key
      chmod 644 /var/lib/nginx/certs/zima.cat-vimba.ts.net.crt
    '';
  };

  systemd.timers.nginx-copy-certs.timerConfig = {
    Persistent = true;
    RandomizedDelaySec = "1h";
  };

  modules.nixos = {
    roles = {
      hosts.enable = true;
    };
  };
}
