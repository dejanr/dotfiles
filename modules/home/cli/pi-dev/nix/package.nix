{ pkgs, pi-dev-src }:

let
  packageJson = builtins.fromJSON (
    builtins.readFile (pi-dev-src + "/packages/coding-agent/package.json")
  );
  version = packageJson.version;
  releaseSource = pkgs.fetchzip {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-${version}-source.tar.gz";
    hash = "sha256-r119A0C/2s7XKFy+LWlZzT4fYOus4jzYe+00n4Tpxxg=";
  };
in
pkgs.buildNpmPackage {
  pname = "pi-dev-coding-agent";
  inherit version;

  src = releaseSource;

  npmDepsHash = "sha256-o4l3zsbLIA/o5VVbZZJV4pZYIEICtp9iUmt69MMxA2o=";
  npmDepsFetcherVersion = 2;

  nodejs = pkgs.nodejs_24;

  nativeBuildInputs = with pkgs; [
    pkg-config
    python3
  ];

  buildInputs =
    with pkgs;
    [
      pixman
      cairo
      pango
      libjpeg
      giflib
      librsvg
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
      pkgs.apple-sdk_15
    ];

  # Ensure node_modules/.bin is in PATH for tsgo
  preBuild = ''
    export PATH="$PWD/node_modules/.bin:$PATH"

    # Skip model generation (needs network) - release source includes generated model files
    substituteInPlace packages/ai/package.json \
      --replace-fail '"build": "npm run generate-models && npm run build:offline"' '"build": "npm run build:offline"'
  '';

  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pi-dev

    cp -r packages $out/lib/pi-dev/
    cp -r node_modules $out/lib/pi-dev/
    cp package.json $out/lib/pi-dev/

    mkdir -p $out/bin
    cat > $out/bin/pi << EOF
    #!/usr/bin/env node
    import("$out/lib/pi-dev/packages/coding-agent/dist/cli.js");
    EOF

    chmod +x $out/bin/pi

    ln -s $out/bin/pi $out/bin/p

    runHook postInstall
  '';
}
