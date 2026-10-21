{ lib, ... }:
let
  blacklist = [
    "Comodo AAA Services root"
    "emSign ECC Root CA - G3"
  ];
  caBundle = "/etc/ssl/certs/ca-certificates.crt";
in
{
  security.pki.caCertificateBlacklist = blacklist;

  environment.variables = {
    SSL_CERT_FILE = lib.mkDefault caBundle;
    REQUESTS_CA_BUNDLE = lib.mkDefault caBundle;
    PIP_CERT = lib.mkDefault caBundle;
    NODE_OPTIONS = lib.mkDefault "--use-openssl-ca";
    UV_NATIVE_TLS = lib.mkDefault "true";
  };
}
