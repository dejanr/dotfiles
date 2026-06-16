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
    hash = "sha256-FaaqfkDvQ3qEmiTlmN9J8Vy1j6wmcibiqD6FktQdrkI=";
  };

  buildPhase = ''
    runHook preBuild

    declaredVersion=$(node -p "JSON.parse(require('fs').readFileSync('package.json', 'utf8')).devDependencies['@earendil-works/pi-coding-agent']")
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
      if [ -f "$dir/dist/index.js" ]; then
        mkdir -p "$out/$dir"
        cp -r "$dir"/{dist,package.json} "$out/$dir/"

        extraFiles=$(node -e '
          const fs = require("fs");
          const path = process.argv[1];
          const pkg = JSON.parse(fs.readFileSync(path, "utf8"));
          for (const file of pkg.files ?? []) console.log(file);
        ' "$dir/package.json")

        if [ -n "$extraFiles" ]; then
          while IFS= read -r file; do
            [ -n "$file" ] || continue
            cp -r "$dir/$file" "$out/$dir/"
          done <<EOF
$extraFiles
EOF
        fi
      fi
    done

    runHook postInstall
  '';
})
