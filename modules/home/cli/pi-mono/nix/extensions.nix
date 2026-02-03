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

  buildScript = pkgs.writeText "build-extension.mjs" ''
    import { readFile } from "node:fs/promises";
    import { createRequire } from "node:module";
    import { resolve } from "node:path";

    const cwd = process.cwd();
    const require = createRequire(resolve(cwd, "..", "package.json"));
    const { build } = require("esbuild");
    const packageJson = JSON.parse(await readFile(resolve(cwd, "package.json"), "utf8"));
    const peerDeps = Object.keys(packageJson.peerDependencies ?? {});

    await build({
      entryPoints: [resolve(cwd, "index.ts")],
      outfile: resolve(cwd, "dist/index.js"),
      bundle: true,
      platform: "node",
      format: "esm",
      target: "node18",
      external: ["@mariozechner/*", ...peerDeps],
    });
  '';
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
    hash = "sha256-NH6fnFPprDwwOb561LmnnaTmiE/0TTS4/x2NI2VZYQo=";
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
