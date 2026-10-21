self: super: {
  nodejs-slim_24 =
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
}
