self: super:
let
  emacsWithPackages = (super.emacsPackagesNgGen super.emacsGit).emacsWithPackages;
  epkgs = super.epkgs.melpaStablePackages;

  nativeStdenv = super.impureUseNativeOptimizations super.stdenv;
  llvmNativeStdenv = super.impureUseNativeOptimizations super.llvmPackages_latest.stdenv;

  withFlags =
    pkg: flags:
    pkg.overrideAttrs (old: {
      NIX_CFLAGS_COMPILE = old.NIX_CFLAGS_COMPILE or "" + super.lib.concatMapStrings (x: " " + x) flags;
    });

  withStdenv = newStdenv: pkg: pkg.override { stdenv = newStdenv; };

  withStdenvAndFlags = newStdenv: pkg: withFlags (withStdenv newStdenv pkg);

  withNativeAndFlags = withStdenvAndFlags nativeStdenv;
  withLLVMNative = withStdenv llvmNativeStdenv;
  withLLVMNativeAndFlags = withStdenvAndFlags llvmNativeStdenv;

  withRustNative =
    pkg:
    pkg.overrideAttrs (old: {
      RUSTFLAGS =
        old.RUSTFLAGS or "" + " -Ctarget-cpu=native -Copt-level=3 -Cdebuginfo=0 -Ccodegen-units=1";
    });

  withRustNativeAndPatches =
    pkg: patches:
    withRustNative (
      pkg.overrideAttrs (old: {
        patches = old.patches or [ ] ++ patches;
      })
    );
in
{
  arc-theme = super.arc-theme.overrideAttrs (oldAttrs: {
    configureFlags = oldAttrs.configureFlags or [ ] ++ [
      "--disable-light"
      "--disable-cinnamon"
      "--disable-gnome-shell"
      "--disable-metacity"
      "--disable-unity"
      "--disable-xfwm"
      "--disable-plank"
      "--disable-openbox"
    ];
  });

  pragmatapro = super.callPackage ./pragmatapro/default.nix { };

  scream-receivers = super.callPackage ./scream-receivers {
    inherit (super)
      stdenv
      lib
      fetchFromGitHub
      alsaLib
      ;
  };

  parsecgaming = super.callPackage ./parsecgaming/default.nix { };

  dotemacs = super.callPackage ./dotemacs {
    inherit (super)
      emacsWithPackages
      epkgs
      symlinkJoin
      makeWrapper
      ;
  };

  beads = super.callPackage ./beads { };
  pulumi = super.callPackage ./pulumi { };
  opencode = super.callPackage ./opencode { };
  rift = super.callPackage ./rift { };
  meshcommander = super.callPackage ./meshcommander { };

  jeveassets = super.callPackage ./jeveassets/default.nix {
    inherit (super)
      stdenv
      fetchzip
      unzip
      jre8
      makeDesktopItem
      ;
  };

  codex = super.callPackage ./codex { };
  ultra-llama-cpp = super.callPackage ./ultra-llama-cpp { };

  # Wrap comfy-ui-cuda launcher to expose CUDA runtime libs for nodes that dlopen()
  comfy-ui-cuda-wrapped =
    if super.stdenv.isLinux && super.stdenv.hostPlatform.isx86_64 then
      super.callPackage ./comfy-ui { }
    else
      super.comfy-ui;

  qutebrowser-unstable =
    let
      mainSrc = super.fetchFromGitHub {
        owner = "qutebrowser";
        repo = "qutebrowser";
        rev = "0774a08ef7294f1bfb9b5b51a2ce88a7128b843d"; # main 2026-02-10
        hash = "sha256-wTluzB2KJ2IaPWNHBub2kDzHEhRhvFe0cS1vv4gnKVg=";
      };
    in
    super.qutebrowser.overrideAttrs (old: {
      version = "3.6.3-unstable-2026-02-10";
      src = mainSrc;
    });

  qutebrowser-nvidia = (
    self.qutebrowser-unstable.override {
      enableVulkan = true;
    }
  );

  niri-release-keybinds = super.rustPlatform.buildRustPackage (finalAttrs: {
    pname = "niri";
    version = "25.11-release-keybinds";

    src = super.fetchFromGitHub {
      owner = "YaLTeR";
      repo = "niri";
      rev = "a5591c69fa81b69d6315f07609acde97eae31c93";
      hash = "sha256-PIJqklpd4pTV4e2ZRJ48etskj9aApVJ0bPCCREVnQjw=";
    };

    outputs = [
      "out"
      "doc"
    ];

    postPatch = ''
      patchShebangs resources/niri-session
      substituteInPlace resources/niri.service \
        --replace-fail "ExecStart=niri --session" "ExecStart=$out/bin/niri --session"
      substituteInPlace resources/niri-session \
        --replace-fail "exec niri --session" "exec $out/bin/niri --session"
      substituteInPlace resources/niri.desktop \
        --replace-fail "Exec=niri-session" "Exec=$out/bin/niri-session"
      substituteInPlace resources/niri.service --replace '/usr/bin' "$out/bin" || true
      substituteInPlace resources/niri.service --replace '/usr' "$out" || true
    '';

    cargoHash = "sha256-mkdn5QY0tWSQ1GhanMNu7v6KiaooSs2oYuvskvzVD3s=";

    strictDeps = true;

    nativeBuildInputs = [
      super.installShellFiles
      super.pkg-config
      super.rustPlatform.bindgenHook
    ];

    buildInputs = [
      super.libdisplay-info
      super.libglvnd
      super.libinput
      super.libxkbcommon
      super.libgbm
      super.pango
      super.seatd
      super.wayland
      super.dbus
      super.pipewire
      super.systemd
    ];

    buildFeatures = [
      "dbus"
      "xdp-gnome-screencast"
      "systemd"
    ];
    buildNoDefaultFeatures = true;

    postInstall = ''
      install -Dm0644 README.md resources/default-config.kdl -t $doc/share/doc/niri
      mv docs/wiki $doc/share/doc/niri/wiki
      install -Dm0644 resources/niri.desktop -t $out/share/wayland-sessions
      install -Dm0644 resources/niri-portals.conf -t $out/share/xdg-desktop-portal
      install -Dm0755 resources/niri-session -t $out/bin
      install -Dm0644 resources/niri{-shutdown.target,.service} -t $out/lib/systemd/user
    '';

    env = {
      RUSTFLAGS = toString (
        map (arg: "-C link-arg=" + arg) [
          "-Wl,--push-state,--no-as-needed"
          "-lEGL"
          "-lwayland-client"
          "-Wl,--pop-state"
        ]
      );
      NIRI_BUILD_COMMIT = "Nixpkgs+release-keybinds";
    };

    checkFlags = [ "--skip=::egl" ];
    doInstallCheck = false;

    passthru.providedSessions = [ "niri" ];

    meta = {
      description = "Scrollable-tiling Wayland compositor";
      homepage = "https://github.com/niri-wm/niri";
      license = super.lib.licenses.gpl3Only;
      mainProgram = "niri";
      platforms = super.lib.platforms.linux;
    };
  });
}
