{
  pkgs,
  extensions-src,
  pi-mono-src,
}:

let
  pnpm = pkgs.pnpm_10;
  nodejs = pkgs.nodejs_24;

  piVersion =
    (builtins.fromJSON (builtins.readFile (pi-mono-src + "/packages/coding-agent/package.json")))
    .version;

  extSrc = pkgs.lib.cleanSourceWith {
    src = extensions-src + "/extensions";
    filter =
      p: _t:
      let
        name = baseNameOf p;
      in
      !builtins.elem name [
        "node_modules"
        "dist"
        ".direnv"
        ".devenv"
      ];
  };

  buildScript = pkgs.writeText "build-extension.mjs" (
    builtins.readFile (extensions-src + "/nix/scripts/build.mjs")
  );
in
pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pi-mono-extensions";
  version = "1.0.0";

  src = extSrc;

  nativeBuildInputs = [
    nodejs
    pnpm
    pkgs.pnpmConfigHook
  ];

  pnpmDeps = pkgs.fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 3;
    hash = "sha256-W6/ZFCRO63/HtBpQgkQuLhvuFbyyncYVW1Z56S6jk2E=";
  };

  buildPhase = ''
    runHook preBuild

    declaredVersion=$(node -p "JSON.parse(require('fs').readFileSync('package.json', 'utf8')).devDependencies['@mariozechner/pi-coding-agent']")
    if [ "${piVersion}" != "$declaredVersion" ]; then
      echo "ERROR: pi-mono version mismatch (input: ${piVersion}, declared: $declaredVersion)" >&2
      exit 1
    fi

    for dir in */; do
      [ -f "$dir/index.ts" ] && echo "Building $dir" && (cd "$dir" && node ${buildScript})
    done

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    for dir in */; do
      [ -f "$dir/dist/index.js" ] && mkdir -p "$out/$dir" && cp -r "$dir"/{dist,package.json} "$out/$dir/"
    done

    runHook postInstall
  '';
})
