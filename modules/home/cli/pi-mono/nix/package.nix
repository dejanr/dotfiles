{ pkgs, pi-mono-src }:

let
  packageJson = builtins.fromJSON (
    builtins.readFile (pi-mono-src + "/packages/coding-agent/package.json")
  );
  version = packageJson.version;
in
pkgs.buildNpmPackage {
  pname = "pi-mono-coding-agent";
  inherit version;

  src = pi-mono-src;

  npmDepsHash = "sha256-Ja3jRlFcA2VOEuti4BLNCWCTLjf2BSt2KeUiEYnbnkM=";

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

    # Skip generate-models (needs network) - use committed models.generated.ts
    substituteInPlace packages/ai/package.json \
      --replace-fail '"build": "npm run generate-models && tsgo' '"build": "tsgo'
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
