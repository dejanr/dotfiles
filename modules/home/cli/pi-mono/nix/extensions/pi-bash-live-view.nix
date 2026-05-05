{ pkgs }:

pkgs.buildNpmPackage rec {
  pname = "pi-bash-live-view";
  version = "0.1.1";

  src = pkgs.fetchFromGitHub {
    owner = "lucasmeijer";
    repo = "pi-bash-live-view";
    rev = "7802f5bdb8a6d7553da03e22fbccb542a634cd72";
    hash = "sha256-/bp0HHlgisO+haaa8NZYGE7wTbTEubMbGhbZLd/BYho=";
  };

  npmDepsHash = "sha256-fL8i5zco61xOZ7lQaI25KNpCCqCdhjPlw8cxhHJ16kw=";

  nodejs = pkgs.nodejs_24;
  dontNpmBuild = true;

  nativeBuildInputs = with pkgs; [
    pkg-config
    python3
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp index.ts pty-execute.ts pty-kill.ts pty-session.ts spawn-helper.ts terminal-emulator.ts truncate.ts widget.ts $out/
    cp package.json README.md LICENSE $out/
    cp -r node_modules $out/
    rm -rf $out/node_modules/@mariozechner $out/node_modules/.bin

    node <<'EOF'
    const fs = require("node:fs");
    const packagePath = process.env.out + "/package.json";
    const packageJson = JSON.parse(fs.readFileSync(packagePath, "utf8"));
    packageJson.peerDependencies = {
      ...packageJson.peerDependencies,
      "@mariozechner/pi-coding-agent": "*",
    };
    delete packageJson.dependencies["@mariozechner/pi-coding-agent"];
    fs.writeFileSync(packagePath, JSON.stringify(packageJson, null, 2) + "\n");
    EOF

    for helper in $out/node_modules/node-pty/prebuilds/darwin-*/spawn-helper; do
      [ -e "$helper" ] && chmod 755 "$helper"
    done

    runHook postInstall
  '';
}
