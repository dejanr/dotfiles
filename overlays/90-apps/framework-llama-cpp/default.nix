{
  lib,
  llama-cpp,
  makeWrapper,
  rocmPackages,
  stdenv,
}:

let
  rocmPackages' = rocmPackages.gfx1151;
in
(llama-cpp.override {
  rocmSupport = true;
  rpcSupport = true;
  rocmPackages = rocmPackages';
  rocmGpuTargets = [ "gfx1151" ];
}).overrideAttrs (oldAttrs: {
  pname = "framework-llama-cpp";

  # Prefer explicit ISA toggles over GGML_NATIVE so the build stays reproducible
  # under Nix while still targeting the local Zen 5 CPU aggressively.
  #
  # - GGML_NATIVE=OFF avoids implicit -march=native behavior.
  # - The AVX/AVX2/VNNI/BMI2/FMA/F16C and AVX-512 toggles keep the fast x86
  #   kernels available for CPU-side work such as sampling, tokenization and
  #   fallback paths.
  # - LLAMA_HIP_UMA=ON is the important Strix Halo knob: the Radeon 8060S iGPU
  #   uses unified memory, so llama.cpp should treat ROCm memory management more
  #   like UMA than a discrete GPU with separate VRAM.
  cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
    "-DGGML_NATIVE=OFF"
    "-DGGML_AVX=ON"
    "-DGGML_AVX_VNNI=ON"
    "-DGGML_AVX2=ON"
    "-DGGML_BMI2=ON"
    "-DGGML_FMA=ON"
    "-DGGML_F16C=ON"
    "-DGGML_AVX512=ON"
    "-DGGML_AVX512_VBMI=ON"
    "-DGGML_AVX512_VNNI=ON"
    "-DGGML_AVX512_BF16=ON"
    "-DLLAMA_HIP_UMA=ON"
  ];

  # Mirror the Strix Halo toolbox HIP tuning: pin the ROCm path explicitly and
  # raise the local unroll threshold for gfx1151 kernels.
  cmakeFlagsArray = (oldAttrs.cmakeFlagsArray or [ ]) ++ [
    "-DCMAKE_HIP_FLAGS=--rocm-path=${rocmPackages'.clr} -mllvm --amdgpu-unroll-threshold-local=600"
  ];

  nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ makeWrapper ];

  # Keep CPU code generation aligned with the local Zen 5 host instead of using
  # generic x86 defaults.
  NIX_CFLAGS_COMPILE = lib.concatStringsSep " " (
    lib.filter (flag: flag != "") [
      (oldAttrs.NIX_CFLAGS_COMPILE or "")
      (lib.optionalString stdenv.hostPlatform.isx86_64 "-march=znver5 -mtune=znver5")
    ]
  );

  # Default to hipBLASLt for all wrapped binaries from this package. This keeps
  # CLI usage simple and matches the runtime tuning used in the Strix Halo tests.
  postFixup = (oldAttrs.postFixup or "") + ''
    for program in llama-batched-bench llama-bench llama-cli llama-completion llama-cvector-generator \
      llama-export-lora llama-fit-params llama-gguf-split llama-imatrix llama-mtmd-cli \
      llama-perplexity llama-quantize llama-rpc-server llama-server llama-tokenize llama-tts rpc-server; do
      if [ -x "$out/bin/$program" ]; then
        wrapProgram "$out/bin/$program" --set-default ROCBLAS_USE_HIPBLASLT 1
      fi
    done
  '';

  meta = oldAttrs.meta // {
    description = "llama.cpp optimized for Framework Desktop Strix Halo with ROCm gfx1151";
  };
})
