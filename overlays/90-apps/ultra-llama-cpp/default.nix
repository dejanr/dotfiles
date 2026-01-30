{
  lib,
  llama-cpp,
  stdenv,
  vulkan-headers,
  vulkan-loader,
  shaderc,
  vulkanSupport ? true,
}:

# Optimized llama-cpp for Apple Silicon (M2 Ultra on Asahi Linux)
# - Native CPU optimizations (-mcpu=native, GGML_NATIVE)
# - Vulkan support via Asahi's Honeykrisp driver
# - No Metal (not available on Asahi Linux)
llama-cpp.overrideAttrs (oldAttrs: {
  pname = "ultra-llama-cpp";

  nativeBuildInputs = oldAttrs.nativeBuildInputs or [ ] ++ lib.optionals vulkanSupport [
    shaderc
  ];

  buildInputs = oldAttrs.buildInputs or [ ] ++ lib.optionals vulkanSupport [
    vulkan-headers
    vulkan-loader
  ];

  cmakeFlags = [
    # Native CPU optimizations for M2 Ultra
    "-DGGML_NATIVE=ON"

    # Server support for OpenAI-compatible API
    "-DLLAMA_BUILD_SERVER=ON"

    # Shared libs
    "-DBUILD_SHARED_LIBS=ON"

    # SSL support
    "-DLLAMA_OPENSSL=ON"

    # Vulkan for Asahi GPU acceleration
    "-DGGML_VULKAN=${if vulkanSupport then "ON" else "OFF"}"

    # Disable other backends
    "-DGGML_BLAS=OFF"
    "-DGGML_METAL=OFF"
    "-DGGML_CUDA=OFF"
  ];

  # Native ARM flags for M2 Ultra
  NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isAarch64 "-mcpu=native";

  meta = oldAttrs.meta // {
    description = "LLaMA.cpp optimized for Apple Silicon (M2 Ultra) with Vulkan";
  };
})
