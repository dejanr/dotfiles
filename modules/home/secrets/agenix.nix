{ pkgs, lib, config, inputs, ... }:

with lib;
let cfg = config.modules.home.secrets.agenix;

in {
  options.modules.home.secrets.agenix = { enable = mkEnableOption "agenix"; };

  config = mkIf cfg.enable {
    age.identityPaths = [ "/home/dejanr/.ssh/agenix" ];
    age.secrets.anthropic_api_key.file = ../../../secrets/anthropic_api_key.age;
    age.secrets.deepseek_api_key.file = ../../../secrets/deepseek_api_key.age;
    age.secrets.groq_api_key.file = ../../../secrets/groq_api_key.age;
    age.secrets.gemini_api_key.file = ../../../secrets/gemini_api_key.age;
    age.secrets.openvpn_office_pass.file = ../../../secrets/openvpn_office_pass.age;
    age.secrets.openvpn_office_conf.file = ../../../secrets/openvpn_office_conf.age;
  };
}

