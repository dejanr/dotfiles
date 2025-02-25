{ pkgs, lib, config, ... }:

# Home related secrets that are exported in ~/.config/sops-nix/secrets

# Use this for not so secret secrets, that should be hidden from general public

{
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.defaultSopsFormat = "yaml";
  sops.age.sshKeyPaths = [ "/home/dejanr/.ssh/id_ed25519" "/Users/dejan.ranisavljevic/.ssh/id_ed25519" ];
  sops.age.keyFile = "/home/dejanr/.config/sops/age/keys.txt";

  sops.secrets.ANTHROPIC_API_KEY = { };
  sops.secrets.DEEPSEEK_API_KEY = { };
  sops.secrets.GROQ_API_KEY = { };
}
