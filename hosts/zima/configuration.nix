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

  systemd.tmpfiles.rules = [
    "d /home/dejanr/downloads 775 dejanr transmission"
    "d /home/dejanr/downloads/incoming 775 dejanr transmission"
    "d /home/dejanr/downloads/incomplete 775 dejanr transmission"
  ];

  # Add nginx user to transmission group so it can read downloads
  users.users.nginx.extraGroups = [ "transmission" ];

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
      settings = {
        rpc-port = 9091;
        peer-port = 51413;
        download-dir = "/home/dejanr/downloads/";
        watch-dir = "/home/dejanr/downloads/incoming";
        trash-original-torrent-files = true;
        incomplete-dir = "/home/dejanr/downloads/incomplete/";
        incomplete-dir-enabled = true;
        rpc-authentication-required = true;
        rpc-whitelist-enabled = true;
        rpc-whitelist = "127.0.0.1,100.*.*.*"; # localhost + Tailscale IP range
        rpc-bind-address = "0.0.0.0";
        rpc-enable = true;
      };
      credentialsFile = config.age.secrets.transmission_credentials.path;
    };
    nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      recommendedProxySettings = true;

      virtualHosts."zima.cat-vimba.ts.net" = {
        root = "/home/dejanr/downloads";
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
      };
    };
  };

  systemd.services.nginx-copy-certs = {
    description = "Copy Tailscale certificates for nginx";
    before = [ "nginx.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /var/lib/nginx/certs
      if [ -f /var/lib/tailscale/certs/zima.cat-vimba.ts.net.crt ]; then
        cp /var/lib/tailscale/certs/zima.cat-vimba.ts.net.crt /var/lib/nginx/certs/
        cp /var/lib/tailscale/certs/zima.cat-vimba.ts.net.key /var/lib/nginx/certs/
        chown -R nginx:nginx /var/lib/nginx/certs
        chmod 600 /var/lib/nginx/certs/*.key
        chmod 644 /var/lib/nginx/certs/*.crt
      fi
    '';
  };

  modules.nixos = {
    roles = {
      hosts.enable = true;
    };
  };
}
