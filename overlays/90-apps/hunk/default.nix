{
  lib,
  stdenv,
  stdenvNoCC,
  bun,
  fetchFromGitHub,
  testers,
  writableTmpDirAsHomeHook,
  colorScheme ? null,
  themeName ? "stylix",
}:

let
  pname = "hunk";
  version = "0.10.0";

  color =
    name:
    let
      value = colorScheme.${name};
    in
    if lib.hasPrefix "#" value then value else "#${value}";

  customTheme =
    if colorScheme == null then
      ""
    else
      ''
        withLazySyntaxStyle(
          {
            id: "${themeName}",
            label: "Stylix",
            appearance: "${colorScheme.polarity or "dark"}",
            background: "${color "base00"}",
            panel: "${color "base01"}",
            panelAlt: "${color "base02"}",
            border: "${color "base03"}",
            accent: "${color "base0D"}",
            accentMuted: "${color "base02"}",
            text: "${color "base05"}",
            muted: "${color "base04"}",
            addedBg: "${color "base01"}",
            removedBg: "${color "base01"}",
            contextBg: "${color "base00"}",
            addedContentBg: "${color "base02"}",
            removedContentBg: "${color "base02"}",
            contextContentBg: "${color "base01"}",
            addedSignColor: "${color "base0B"}",
            removedSignColor: "${color "base08"}",
            lineNumberBg: "${color "base00"}",
            lineNumberFg: "${color "base04"}",
            selectedHunk: "${color "base02"}",
            badgeAdded: "${color "base0B"}",
            badgeRemoved: "${color "base08"}",
            badgeNeutral: "${color "base0D"}",
            fileNew: "${color "base0B"}",
            fileDeleted: "${color "base08"}",
            fileRenamed: "${color "base0A"}",
            fileModified: "${color "base0E"}",
            fileUntracked: "${color "base0C"}",
            noteBorder: "${color "base0E"}",
            noteBackground: "${color "base01"}",
            noteTitleBackground: "${color "base02"}",
            noteTitleText: "${color "base05"}",
          },
          {
            default: "${color "base05"}",
            keyword: "${color "base0E"}",
            string: "${color "base0B"}",
            comment: "${color "base03"}",
            number: "${color "base09"}",
            function: "${color "base0D"}",
            property: "${color "base0C"}",
            type: "${color "base0A"}",
            punctuation: "${color "base04"}",
          },
        ),
      '';

  src = fetchFromGitHub {
    owner = "modem-dev";
    repo = "hunk";
    tag = "v${version}";
    hash = "sha256-S2EuZW5vzyk3FGhUQbyanE3hdlnb9F6GQMtu2k8pjrM=";
  };

  node_modules = stdenvNoCC.mkDerivation {
    pname = "${pname}-node_modules";
    inherit version src;

    impureEnvVars = lib.fetchers.proxyImpureEnvVars ++ [
      "GIT_PROXY_COMMAND"
      "SOCKS_SERVER"
    ];

    nativeBuildInputs = [
      bun
      writableTmpDirAsHomeHook
    ];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install \
        --frozen-lockfile \
        --ignore-scripts \
        --no-progress

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out
      cp -R node_modules $out/

      runHook postInstall
    '';

    dontFixup = true;

    outputHash = "sha256-xaX/QlcmWK9UvTkWcnfvJhMXqENmuMr0S0BItmkow7A=";
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
stdenv.mkDerivation (finalAttrs: {
  inherit
    pname
    version
    src
    node_modules
    ;

  nativeBuildInputs = [ bun ];

  postPatch = lib.optionalString (colorScheme != null) ''
      substituteInPlace src/ui/themes.ts \
        --replace-fail 'export const THEMES: AppTheme[] = [' 'export const THEMES: AppTheme[] = [
    ${customTheme}'
      substituteInPlace src/opentui/themes.ts \
        --replace-fail '["graphite", "midnight", "paper", "ember"]' '["${themeName}", "graphite", "midnight", "paper", "ember"]'
  '';

  configurePhase = ''
    runHook preConfigure

    cp -R ${node_modules}/node_modules ./node_modules
    chmod -R u+w ./node_modules

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    export BUN_TMPDIR=$TMPDIR/bun-tmp
    export BUN_INSTALL=$TMPDIR/bun-install
    bun build --compile ./src/main.tsx --outfile ./dist/hunk

    runHook postBuild
  '';

  dontStrip = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 ./dist/hunk $out/bin/hunk
    install -Dm644 ./skills/hunk-review/SKILL.md $out/skills/hunk-review/SKILL.md

    runHook postInstall
  '';

  passthru.tests.version = testers.testVersion {
    package = finalAttrs.finalPackage;
    command = "hunk --version";
    inherit version;
  };

  meta = {
    description = "Review-first terminal diff viewer for agent-authored changesets";
    homepage = "https://github.com/modem-dev/hunk";
    license = lib.licenses.mit;
    mainProgram = "hunk";
    platforms = [
      "aarch64-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
  };
})
