{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.modules.nixos.roles.ctf;
  podmanDockerConfig = pkgs.writeTextDir "config.json" ''
    { "auths": { } }
  '';
  podmanDockerCompat = pkgs.writeShellScriptBin "docker" ''
    export DOCKER_CONFIG="''${DOCKER_CONFIG:-${podmanDockerConfig}}"
    exec ${lib.getExe pkgs.podman} --remote --url unix:///run/podman/podman.sock "$@"
  '';
in
{
  options.modules.nixos.roles.ctf.enable = lib.mkEnableOption "local CTF development";

  config = lib.mkIf cfg.enable {
    age.secrets.work_hosts.file = ../../../secrets/work_hosts.age;

    system.activationScripts.workHosts = {
      deps = [
        "agenix"
        "etc"
      ];
      text = ''
        install -m 0644 /etc/static/hosts /run/hosts
        cat ${config.age.secrets.work_hosts.path} >> /run/hosts
        ln -sfn /run/hosts /etc/hosts
      '';
    };

    virtualisation.podman = {
      enable = true;
      dockerCompat = lib.mkForce false;
      dockerSocket.enable = true;
    };

    home-manager.users.dejanr.home.sessionVariables = {
      JIRA_SITE = "https://burdaforward.atlassian.net";
      JIRA_EMAIL = "dejan.ranisavljevic@burda-forward.de";
      JIRA_TOKEN_TYPE = "scoped";
      JIRA_CLOUD_ID = "885940eb-9c52-48ae-bc77-21be8e48d472";
      JIRA_PROJECT = "CTF";
    };

    home-manager.users.dejanr.home.packages = with pkgs; [
      microsoft-rush
      jira-cli-go
      glab
      mongosh
      pm2
    ];

    environment.systemPackages = [ podmanDockerCompat ];
    users.users.dejanr.extraGroups = [ "podman" ];
    networking.firewall.trustedInterfaces = [ "podman0" ];

    security.pki.certificateFiles = [ ../../../certs/ctf-local-root.crt ];
    systemd.tmpfiles.rules = [ "d /tmp/localstack 0777 root root -" ];
    systemd.services.caddy.wantedBy = lib.mkIf config.services.caddy.enable (lib.mkForce [ ]);

    modules.nixos.roles.hosts = {
      enable = true;
      blocklist.enable = false;
    };
  };
}
