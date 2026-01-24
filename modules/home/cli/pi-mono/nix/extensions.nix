{ pkgs, extensions-src, pi-mono-src }:

pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pi-mono-extensions";
  version = "1.0.0";

  src = extensions-src;
  sourceRoot = "extensions";

  nativeBuildInputs = [
    pkgs.nodejs_24
    pkgs.pnpm
    pkgs.pnpmConfigHook
  ];

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit (finalAttrs) pname version src sourceRoot;
    hash = "sha256-fGO1E8aFnDPMhPaw1hBhAX29r9JYHRnmzAxofT48jcw=";
    fetcherVersion = 2;
    unpackPhase = ''
      runHook preUnpack
      cp -r $src/. .
      chmod -R u+w .
      runHook postUnpack
    '';
  };

  unpackPhase = ''
    runHook preUnpack
    cp -r $src/. .
    chmod -R u+w .
    runHook postUnpack
  '';

  buildPhase = ''
    runHook preBuild

    expectedVersion=$(node -p "JSON.parse(require('fs').readFileSync('${pi-mono-src}/packages/coding-agent/package.json', 'utf8')).version")
    declaredVersion=$(node -p "JSON.parse(require('fs').readFileSync('package.json', 'utf8')).devDependencies['@mariozechner/pi-coding-agent']")
    if [ "$expectedVersion" != "$declaredVersion" ]; then
      echo "Expected @mariozechner/pi-coding-agent version $expectedVersion but extensions declare $declaredVersion" >&2
      exit 1
    fi

    pnpm install --frozen-lockfile --offline --ignore-scripts
    pnpm -r run build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"

    for extension in */; do
      if [ -f "$extension/package.json" ]; then
        mkdir -p "$out/$extension"
        cp -r "$extension/dist" "$extension/package.json" "$out/$extension/"
      fi
    done

    runHook postInstall
  '';
})
