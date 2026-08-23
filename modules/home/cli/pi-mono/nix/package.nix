{ pkgs, pi-mono-src }:

let
  packageJson = builtins.fromJSON (
    builtins.readFile (pi-mono-src + "/packages/coding-agent/package.json")
  );
  version = packageJson.version;
  releaseSource = pkgs.fetchzip {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-${version}-source.tar.gz";
    hash = "sha256-UJr6NAfjKM/xldjmyx4W28K9I8jJz/dh3vz6eLi1I40=";
  };
in
pkgs.buildNpmPackage {
  pname = "pi-mono-coding-agent";
  inherit version;

  src = releaseSource;

  npmDepsHash = "sha256-23Z/SwEnwriAmWiP+4TUG9k6P5+RSTvjL7mhRPwWk98=";
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
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
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

    mkdir -p $out/lib/pi-mono

    cp -r packages $out/lib/pi-mono/
    cp -r node_modules $out/lib/pi-mono/
    cp package.json $out/lib/pi-mono/

    mkdir -p $out/bin
    cat > $out/bin/pi << EOF
    #!/usr/bin/env node
    import("$out/lib/pi-mono/packages/coding-agent/dist/cli.js");
    EOF

    chmod +x $out/bin/pi

    ln -s $out/bin/pi $out/bin/p

    runHook postInstall
  '';
}
