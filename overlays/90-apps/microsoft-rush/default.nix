{
  lib,
  buildNpmPackage,
  nodejs,
}:

buildNpmPackage rec {
  pname = "microsoft-rush";
  version = "5.178.0";

  src = ./.;

  npmDepsHash = "sha256-1v+KTcDvGUS1JYZ3vRJIn6ZrzKeYnfUsxmCrOkQkVPg=";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/microsoft-rush $out/bin
    cp -r node_modules $out/lib/microsoft-rush/

    for bin in rush rush-pnpm rushx; do
      makeWrapper ${nodejs}/bin/node $out/bin/$bin \
        --add-flags $out/lib/microsoft-rush/node_modules/@microsoft/rush/bin/$bin
    done

    runHook postInstall
  '';

  meta = {
    description = "A professional solution for consolidating all your JavaScript projects in one Git repo";
    homepage = "https://rushjs.io";
    license = lib.licenses.mit;
    mainProgram = "rush";
    platforms = lib.platforms.unix;
  };
}
