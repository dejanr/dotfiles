{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_24,
}:

buildNpmPackage {
  pname = "figma-bridge";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "SuTang-vain";
    repo = "figma-bridge";
    rev = "64b0d68797f86bb71ed8f6b0abf173215279960c";
    hash = "sha256-F4In/7Ki2+nxnqIbW2qu5Npi+GrKmI449WamsWAoZKo=";
  };

  nodejs = nodejs_24;
  npmDepsHash = "sha256-+8QrVEDj9nhDkM5hOyPjiLuGZvXqSVdkAL5Juts4afY=";
  npmFlags = [ "--ignore-scripts" ];
  dontNpmBuild = true;

  patches = [ ./pinned-cli-skill.patch ];

  meta = {
    description = "Inspect Figma design data from the CLI and Pi";
    homepage = "https://github.com/SuTang-vain/figma-bridge";
    license = lib.licenses.mit;
    mainProgram = "figma-bridge";
  };
}
