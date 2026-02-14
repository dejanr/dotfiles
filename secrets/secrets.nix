let
  agenix-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILPvj/ZE/vb6CWIhmcHgYtm0qryvK/3whB8RZ68tzqFk";

  publicKeys = [ agenix-key ];
in
{
  "anthropic_api_key.age".publicKeys = publicKeys;
  "deepseek_api_key.age".publicKeys = publicKeys;
  "groq_api_key.age".publicKeys = publicKeys;
  "gemini_api_key.age".publicKeys = publicKeys;
  "qutebrowser_quickmarks.age".publicKeys = publicKeys;
  "qutebrowser_bookmarks_personal.age".publicKeys = publicKeys;
  "qutebrowser_bookmarks_work.age".publicKeys = publicKeys;
  "qutebrowser_bookmarks_futurice.age".publicKeys = publicKeys;
  "elevenlabs_api_key.age".publicKeys = publicKeys;
  "exa_api_key.age".publicKeys = publicKeys;
  "github_runner_token_dejli.age".publicKeys = publicKeys;
  "caddy_local_root_crt.age".publicKeys = publicKeys;
}
