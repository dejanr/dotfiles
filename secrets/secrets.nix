let
  agenix-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILPvj/ZE/vb6CWIhmcHgYtm0qryvK/3whB8RZ68tzqFk";

  publicKeys = [ agenix-key ];
in
{
  "anthropic_api_key.age".publicKeys = publicKeys;
  "deepseek_api_key.age".publicKeys = publicKeys;
  "groq_api_key.age".publicKeys = publicKeys;
  "gemini_api_key.age".publicKeys = publicKeys;
  "openvpn_office_pass.age".publicKeys = publicKeys;
  "openvpn_office_conf.age".publicKeys = publicKeys;
}

