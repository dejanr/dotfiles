{
  ...
}:

# System related secrets that are managed by agenix
# Use this for system wide secrets, that should be only accessible by sudo

{
  age.identityPaths = [ "/home/dejanr/.ssh/agenix" ];

  age.secrets.transmission_credentials = {
    file = ../../../secrets/transmission_credentials.age;
    owner = "transmission";
    group = "transmission";
  };
}
