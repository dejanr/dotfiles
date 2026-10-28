{ pkgs, pi-dev-src }:

let
  packageJson = builtins.fromJSON (
    builtins.readFile (pi-dev-src + "/packages/coding-agent/package.json")
  );
  version = packageJson.version;
  releaseSource = pkgs.fetchzip {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-${version}-source.tar.gz";
    hash = "sha256-1CKtkAEKJrPeHZ52nrDKyAhGV+iWitVO4fWjmG+skEk=";
  };
in
pkgs.buildNpmPackage (finalAttrs: {
  pname = "pi-dev-coding-agent";
  inherit version;

  src = releaseSource;

  patches = [ ./primary-selection.patch ];

  npmDepsHash = "sha256-9VJZVr+agPjtjjpE7zybqDkVTYpVEyr64LiY2Hq5J7g=";
  npmDepsFetcherVersion = 2;

  nodejs = pkgs.nodejs_24-patched;

  nativeBuildInputs = with pkgs; [
    makeWrapper
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

  postFixup = pkgs.lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
    wrapProgram $out/bin/pi --set-default PI_CLIPBOARD_OSC52 1 --prefix PATH : ${
      pkgs.lib.makeBinPath [
        pkgs.wl-clipboard
        pkgs.xclip
        pkgs.xsel
      ]
    }
  '';

  passthru.tests = pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    tmux-clipboard =
      pkgs.runCommand "pi-dev-tmux-clipboard-test"
        {
          nativeBuildInputs = [
            pkgs.python3
            pkgs.tmux
          ];
        }
        ''
          python3 ${./clipboard-tmux.test.py} ${finalAttrs.finalPackage}
          touch "$out"
        '';
  };

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
})
