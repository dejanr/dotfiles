{
  lib,
  buildGo124Module,
  fetchFromGitHub,
  fetchpatch,
  buildEnv,
  linkFarm,
  makeWrapper,
  stdenv,
  addDriverRunpath,
  nix-update-script,
  cmake,
  gitMinimal,
  clblast,
  libdrm,
  rocmPackages,
  rocmGpuTargets ? rocmPackages.clr.gpuTargets or [ ],
  cudaPackages,
  cudaArches ? cudaPackages.flags.realArches or [ ],
  darwin,
  autoAddDriverRunpath,
  versionCheckHook,
  # passthru
  nixosTests,
  testers,
  ollama,
  ollama-rocm,
  ollama-cuda,
  config,
  # one of `[ null false "rocm" "cuda" ]`
  acceleration ? null,
}:

assert builtins.elem acceleration [
  null
  false
  "rocm"
  "cuda"
];

let
  pname = "ollama";
  # don't forget to invalidate all hashes each update
  version = "0.6.0";

  buildGoModule = buildGo124Module;

  src = fetchFromGitHub {
    owner = "ollama";
    repo = "ollama";
    tag = "v${version}";
    hash = "sha256-xcnzLBrTbH5IRDZoUR0OoXslcTvml9d/jnQEM52Rmyg=";
    fetchSubmodules = true;
  };

  vendorHash = "sha256-Zpzn2YWpiDAl4cwgrrSpN8CFy4GqqhE1mWsRxtYwdDA=";

  validateFallback = lib.warnIf (config.rocmSupport && config.cudaSupport) (lib.concatStrings [
    "both `nixpkgs.config.rocmSupport` and `nixpkgs.config.cudaSupport` are enabled, "
    "but they are mutually exclusive; falling back to cpu"
  ]) (!(config.rocmSupport && config.cudaSupport));
  shouldEnable =
    mode: fallback: (acceleration == mode) || (fallback && acceleration == null && validateFallback);

  rocmRequested = shouldEnable "rocm" config.rocmSupport;
  cudaRequested = shouldEnable "cuda" config.cudaSupport;

  enableRocm = rocmRequested && stdenv.hostPlatform.isLinux;
  enableCuda = cudaRequested && stdenv.hostPlatform.isLinux;

  rocmLibs = [
    rocmPackages.clr
    rocmPackages.hipblas
    rocmPackages.rocblas
    rocmPackages.rocsolver
    rocmPackages.rocsparse
    rocmPackages.rocm-device-libs
    rocmPackages.rocm-smi
  ];
  rocmClang = linkFarm "rocm-clang" { llvm = rocmPackages.llvm.clang; };
  rocmPath = buildEnv {
    name = "rocm-path";
    paths = rocmLibs ++ [ rocmClang ];
  };

  cudaLibs = [
    cudaPackages.cuda_cudart
    cudaPackages.libcublas
    cudaPackages.cuda_cccl
  ];

  # Extract the major version of CUDA. e.g. 11 12
  cudaMajorVersion = lib.versions.major cudaPackages.cuda_cudart.version;

  cudaToolkit = buildEnv {
    # ollama hardcodes the major version in the Makefile to support different variants.
    # - https://github.com/ollama/ollama/blob/v0.4.4/llama/Makefile#L17-L18
    name = "cuda-merged-${cudaMajorVersion}";
    paths = map lib.getLib cudaLibs ++ [
      (lib.getOutput "static" cudaPackages.cuda_cudart)
      (lib.getBin (cudaPackages.cuda_nvcc.__spliced.buildHost or cudaPackages.cuda_nvcc))
    ];
  };

  cudaPath = lib.removeSuffix "-${cudaMajorVersion}" cudaToolkit;

  metalFrameworks = with darwin.apple_sdk_11_0.frameworks; [
    Accelerate
    Metal
    MetalKit
    MetalPerformanceShaders
  ];

  wrapperOptions =
    [
      # ollama embeds llama-cpp binaries which actually run the ai models
      # these llama-cpp binaries are unaffected by the ollama binary's DT_RUNPATH
      # LD_LIBRARY_PATH is temporarily required to use the gpu
      # until these llama-cpp binaries can have their runpath patched
      "--suffix LD_LIBRARY_PATH : '${addDriverRunpath.driverLink}/lib'"
    ]
    ++ lib.optionals enableRocm [
      "--suffix LD_LIBRARY_PATH : '${rocmPath}/lib'"
      "--set-default HIP_PATH '${rocmPath}'"
    ]
    ++ lib.optionals enableCuda [
      "--suffix LD_LIBRARY_PATH : '${lib.makeLibraryPath (map lib.getLib cudaLibs)}'"
    ];
  wrapperArgs = builtins.concatStringsSep " " wrapperOptions;

  goBuild =
    if enableCuda then
      buildGoModule.override { stdenv = cudaPackages.backendStdenv; }
    else
      buildGoModule;
  inherit (lib) licenses platforms maintainers;
in
goBuild {
  inherit
    pname
    version
    src
    vendorHash
    ;

  env =
    lib.optionalAttrs enableRocm {
      ROCM_PATH = rocmPath;
      CLBlast_DIR = "${clblast}/lib/cmake/CLBlast";
      HIP_PATH = rocmPath;
    }
    // lib.optionalAttrs enableCuda { CUDA_PATH = cudaPath; };

  nativeBuildInputs =
    [
      cmake
      gitMinimal
    ]
    ++ lib.optionals enableRocm [
      rocmPackages.llvm.bintools
      rocmLibs
    ]
    ++ lib.optionals enableCuda [ cudaPackages.cuda_nvcc ]
    ++ lib.optionals (enableRocm || enableCuda) [
      makeWrapper
      autoAddDriverRunpath
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin metalFrameworks;

  buildInputs =
    lib.optionals enableRocm (rocmLibs ++ [ libdrm ])
    ++ lib.optionals enableCuda cudaLibs
    ++ lib.optionals stdenv.hostPlatform.isDarwin metalFrameworks;

  # replace inaccurate version number with actual release version
  postPatch = ''
    substituteInPlace version/version.go \
      --replace-fail 0.0.0 '${version}'
  '';

  overrideModAttrs = (
    finalAttrs: prevAttrs: {
      # don't run llama.cpp build in the module fetch phase
      preBuild = "";
    }
  );

  preBuild =
    let
      removeSMPrefix =
        str:
        let
          matched = builtins.match "sm_(.*)" str;
        in
        if matched == null then str else builtins.head matched;

      cudaArchitectures = builtins.concatStringsSep ";" (builtins.map removeSMPrefix cudaArches);
      rocmTargets = builtins.concatStringsSep ";" rocmGpuTargets;

      cmakeFlagsCudaArchitectures = lib.optionalString enableCuda "-DCMAKE_CUDA_ARCHITECTURES='${cudaArchitectures}'";
      cmakeFlagsRocmTargets = lib.optionalString enableRocm "-DAMDGPU_TARGETS='${rocmTargets}'";

    in
    ''
      cmake -B build \
        -DCMAKE_SKIP_BUILD_RPATH=ON \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
        ${cmakeFlagsCudaArchitectures} \
        ${cmakeFlagsRocmTargets} \

      cmake --build build -j $NIX_BUILD_CORES
    '';

  # ollama looks for acceleration libs in ../lib/ollama/ (now also for CPU-only with arch specific optimizations)
  # https://github.com/ollama/ollama/blob/v0.5.11/docs/development.md#library-detection
  postInstall = ''
    mkdir -p $out/lib
    cp -r build/lib/ollama $out/lib/
  '';

  postFixup =
    # the app doesn't appear functional at the moment, so hide it
    ''
      mv "$out/bin/app" "$out/bin/.ollama-app"
    ''
    # expose runtime libraries necessary to use the gpu
    + lib.optionalString (enableRocm || enableCuda) ''
      wrapProgram "$out/bin/ollama" ${wrapperArgs}
    '';

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/ollama/ollama/version.Version=${version}"
    "-X=github.com/ollama/ollama/server.mode=release"
  ];

  __darwinAllowLocalNetworking = true;

  nativeInstallCheck = [ versionCheckHook ];
  versionCheckProgramArg = [ "--version" ];
  doInstallCheck = true;

  passthru = {
    tests =
      {
        inherit ollama;
        version = testers.testVersion {
          inherit version;
          package = ollama;
        };
      }
      // lib.optionalAttrs stdenv.hostPlatform.isLinux {
        inherit ollama-rocm ollama-cuda;
        service = nixosTests.ollama;
        service-cuda = nixosTests.ollama-cuda;
        service-rocm = nixosTests.ollama-rocm;
      };
  } // lib.optionalAttrs (!enableRocm && !enableCuda) { updateScript = nix-update-script { }; };

  meta = {
    description =
      "Get up and running with large language models locally"
      + lib.optionalString rocmRequested ", using ROCm for AMD GPU acceleration"
      + lib.optionalString cudaRequested ", using CUDA for NVIDIA GPU acceleration";
    homepage = "https://github.com/ollama/ollama";
    changelog = "https://github.com/ollama/ollama/releases/tag/v${version}";
    license = licenses.mit;
    platforms = if (rocmRequested || cudaRequested) then platforms.linux else platforms.unix;
    mainProgram = "ollama";
    maintainers = with maintainers; [
      abysssol
      dit7ya
      elohmeier
      prusnak
      roydubnium
    ];
  };
}
