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
}
