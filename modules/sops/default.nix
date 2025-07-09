{ pkgs, lib, config, ... }:

with lib;
let cfg = config.modules.sops;

in {
  options.modules.sops = { enable = mkEnableOption "sops"; };

  config = mkIf cfg.enable {
    sops.defaultSopsFile = ../../secrets/secrets.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = [ "/home/dejanr/.ssh/id_ed25519" "/Users/dejan.ranisavljevic/.ssh/id_ed25519" "/home/dejanr/.ssh/id_ed25519_old" ];
    sops.age.keyFile = "/home/dejanr/.config/sops/age/keys.txt";

    sops.secrets.ANTHROPIC_API_KEY = { };
    sops.secrets.DEEPSEEK_API_KEY = { };
    sops.secrets.GROQ_API_KEY = { };
  };
}
