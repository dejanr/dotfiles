{
  ...
}:

# System related secrets that are managed by agenix
# Prefer host SSH keys so decryption works during boot before /home is available,
# but keep the user key as a fallback for hosts not yet rekeyed.

{
  age.identityPaths = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_rsa_key"
    "/home/dejanr/.ssh/agenix"
  ];
}
