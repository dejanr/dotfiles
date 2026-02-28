let
  agenixKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILPvj/ZE/vb6CWIhmcHgYtm0qryvK/3whB8RZ68tzqFk";
  frameworkHostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1kEkLAbGZb9u9IiXpV/q92dRnmW3xm8Ysn0QdHp++D root@framework";

  userKeys = [ agenixKey ];
  caddyKeys = [
    agenixKey
    frameworkHostKey
  ];
in
{
  "anthropic_api_key.age".publicKeys = userKeys;
  "deepseek_api_key.age".publicKeys = userKeys;
  "groq_api_key.age".publicKeys = userKeys;
  "gemini_api_key.age".publicKeys = userKeys;
  "qutebrowser_quickmarks.age".publicKeys = userKeys;
  "qutebrowser_bookmarks_personal.age".publicKeys = userKeys;
  "qutebrowser_bookmarks_work.age".publicKeys = userKeys;
  "qutebrowser_bookmarks_futurice.age".publicKeys = userKeys;
  "elevenlabs_api_key.age".publicKeys = userKeys;
  "exa_api_key.age".publicKeys = userKeys;
  "huggingface_api_key.age".publicKeys = userKeys;

  "caddy_local_root_key.age".publicKeys = caddyKeys;
}
