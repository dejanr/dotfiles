{
  lib,
  nodejs,
  buildNpmPackage,
  fetchFromGitHub,
}:

buildNpmPackage rec {
  pname = "mesh-mini";
  version = "2024-05-26";

  src = fetchFromGitHub {
    owner = "brytonsalisbury";
    repo = pname;
    rev = "2870bac";
    hash = "sha256-4cJSE6Q+qnXcxsLKmJ+qOLM2ymqc7k9ZbvyFHFwy3WE=";
  };

  NODE_ENV = "production";
  npmDepsHash = "sha256-tjkpM1UzTPw0q0xx3A5of4TJTWLCp2bT2YRUnjpWj4c=";

  dontNpmBuild = true;

  postInstall = ''
    makeWrapper  ${nodejs}/bin/node $out/bin/meshcommander \
      --add-flags $out/lib/node_modules/mesh-mini/meshcommander.js
  '';

  meta = {
    description = " A faster, bundled version of MeshCommander that runs on localhost in a browser. ";
    homepage = "https://github.com/brytonsalisbury/mesh-mini";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ makefu ];
  };
}
