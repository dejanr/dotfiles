{ pkgs, lib }:

let
  runtimeLibraries = with pkgs; [
    alsa-lib
    at-spi2-core
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libxkbcommon
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxscrnsaver
    libxtst
    libxcb
    libxshmfence
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    systemd
    vulkan-loader
    wayland
  ];
  cefArchive = "cef_binary_152.0.6+g708dc14+chromium-152.0.7977.83_linux64_minimal.tar.bz2";
  cef = pkgs.stdenv.mkDerivation {
    pname = "buffr-cef-runtime";
    version = "152.0.6";
    src = pkgs.fetchurl {
      url = "https://cef-builds.spotifycdn.com/${cefArchive}";
      hash = "sha256-2vjCtuY3h9apHWZiBaikUhQZk36rr0dyNzjIaupxNb0=";
    };

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];
    buildInputs = runtimeLibraries;
    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r Release/. Resources/. include cmake libcef_dll CMakeLists.txt CREDITS.html LICENSE.txt "$out/"
      rm "$out/libvulkan.so.1"
      cat > "$out/archive.json" <<'EOF'
      ${builtins.toJSON {
        type = "minimal";
        name = cefArchive;
        sha1 = "9711b86c105fb590da576fe5a829802f1a79d520";
      }}
      EOF
      runHook postInstall
    '';
  };
in
pkgs.rustPlatform.buildRustPackage {
  pname = "buffr";
  version = "0.14.17";

  src = pkgs.fetchFromGitHub {
    owner = "kryptic-sh";
    repo = "buffr";
    rev = "7370d3058b99274d98eb8d913d27a695b5512342";
    hash = "sha256-UAMhoFPnqIak7h+/eaMWcJIX3Mwk8PIDQmbbZETtyz0=";
  };
  patches = [
    ./linux-window.patch
    ./profile-label.patch
  ];
  cargoHash = "sha256-g0fq7F1gCHjI1wpHm/ZWMhnKyornjhKc5gQAbchhsL8=";

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    makeWrapper
    pkg-config
  ];
  buildInputs = runtimeLibraries;
  nativeCheckInputs = [ pkgs.python3 ];

  env.CEF_PATH = cef;

  postPatch = ''
    substituteInPlace apps/buffr/tests/clean_exit.rs \
      --replace-fail '"/bin/true"' '"${pkgs.coreutils}/bin/true"'
    substituteInPlace apps/buffr/tests/*.rs apps/buffr/tests/common/mod.rs \
      --replace '#!/bin/sh' '#!${pkgs.runtimeShell}' \
      --replace '#!/usr/bin/env python3' '#!${pkgs.python3}/bin/python3'
  '';

  cargoBuildFlags = [
    "-p"
    "buffr"
    "-p"
    "buffr-app"
    "-p"
    "buffr-helper"
  ];
  cargoTestFlags = [ "--workspace" ];
  preCheck = ''
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib/buffr" "$out/bin"
    cp -r ${cef}/. "$out/lib/buffr/"
    chmod -R u+w "$out/lib/buffr"
    rm -r "$out/lib/buffr/"{include,cmake,libcef_dll,CMakeLists.txt,archive.json}
    for binary in buffr buffr-app buffr-helper; do
      install -m755 "target/${pkgs.stdenv.hostPlatform.rust.rustcTarget}/release/$binary" "$out/lib/buffr/$binary"
      makeWrapper "$out/lib/buffr/$binary" "$out/bin/$binary" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibraries}"
    done
    install -Dm644 LICENSE "$out/share/licenses/buffr/LICENSE"
    install -Dm644 pkg/buffr.desktop "$out/share/applications/sh.kryptic.buffr.desktop"
    substituteInPlace "$out/share/applications/sh.kryptic.buffr.desktop" \
      --replace-fail 'StartupWMClass=buffr' 'StartupWMClass=sh.kryptic.buffr'
    install -Dm644 pkg/buffr.png "$out/share/icons/hicolor/256x256/apps/buffr.png"
    runHook postInstall
  '';

  meta = {
    description = "Vim-inspired GPU-accelerated browser built on CEF";
    homepage = "https://github.com/kryptic-sh/buffr";
    license = lib.licenses.mit;
    mainProgram = "buffr";
    platforms = [ "x86_64-linux" ];
  };
}
