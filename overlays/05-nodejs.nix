self: super: {
  nodejs-slim_24-patched =
    if super.lib.versionAtLeast super.nodejs-slim_24.version "24.22.1" then
      super.nodejs-slim_24
    else
      super.nodejs-slim_24.overrideAttrs (
        finalAttrs: oldAttrs: {
          version = "24.22.1";
          src = self.fetchurl {
            url = "https://nodejs.org/dist/v${finalAttrs.version}/node-v${finalAttrs.version}.tar.xz";
            hash = "sha256-T1N5eWKAza6wwvNY/QS2oWzE+336g7WoyRqdljtDUjE=";
          };
          # The bundled Brotli has API changes absent from the pinned system library.
          configureFlags = builtins.filter (
            flag: !(super.lib.hasPrefix "--shared-brotli" flag)
          ) oldAttrs.configureFlags;
          buildInputs = super.lib.remove super.brotli oldAttrs.buildInputs;
        }
      );

  nodejs_24-patched = super.nodejs_24.override {
    nodejs-slim = self.nodejs-slim_24-patched;
  };

  pm2 = super.pm2.override {
    buildNpmPackage = super.buildNpmPackage.override {
      nodejs = self.nodejs_24-patched;
    };
  };
}
