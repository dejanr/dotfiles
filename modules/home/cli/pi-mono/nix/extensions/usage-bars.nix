{ pkgs }:

pkgs.stdenvNoCC.mkDerivation {
  pname = "pi-usage-bars";
  version = "0.6.0";

  src = pkgs.fetchFromGitHub {
    owner = "hknet";
    repo = "pi-usage-bars";
    rev = "143140c3087b4a357dc42c79dbf195061e2b8fc2";
    hash = "sha256-f1ul9fjh3RECPVrFJqD7p4yZfmyg9fdt8NmSKhFvTDk=";
  };

  nativeBuildInputs = [
    pkgs.esbuild
    pkgs.jq
  ];

  buildPhase = ''
    runHook preBuild

    esbuild extensions/usage-bars/index.ts \
      --bundle \
      --platform=node \
      --format=esm \
      --target=node22 \
      '--external:@earendil-works/*' \
      --outfile=dist/index.js

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/dist
    cp dist/index.js $out/dist/
    cp README.md LICENSE $out/
    jq '.pi.extensions = ["./dist/index.js"]' package.json > $out/package.json

    runHook postInstall
  '';

  meta = {
    description = "Quota, balance, and spend indicators for Pi providers";
    homepage = "https://github.com/hknet/pi-usage-bars";
    license = pkgs.lib.licenses.mit;
  };
}
