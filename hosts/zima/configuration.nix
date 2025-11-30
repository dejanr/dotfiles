{
  pkgs,
  config,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
  ];

  systemd.tmpfiles.rules = [
    "d /home/dejanr/downloads 775 dejanr wheel"
    "d /home/dejanr/downloads/incoming 775 dejanr wheel"
    "d /home/dejanr/downloads/incomplete 775 dejanr wheel"
  ];

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
      openRPCPort = true;
      package = pkgs.transmission_4;
      settings = {
        rpc-port = 9091;
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
        sslCertificate = "/var/lib/tailscale/certs/zima.cat-vimba.ts.net.crt";
        sslCertificateKey = "/var/lib/tailscale/certs/zima.cat-vimba.ts.net.key";
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

  modules.nixos = {
    roles = {
      hosts.enable = true;
    };
  };
}
