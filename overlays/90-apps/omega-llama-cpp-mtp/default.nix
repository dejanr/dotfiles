{
  lib,
  llama-cpp,
  fetchFromGitHub,
  cudaPackages,
}:

let
  cudaPackages' = cudaPackages.overrideScope (
    _final: prev: {
      cuda_compat = null;
      cuda_cudart = prev.cuda_cudart.override { cuda_compat = null; };
    }
  );
in
(llama-cpp.override {
  cudaSupport = true;
  rpcSupport = true;
  cudaPackages = cudaPackages';
}).overrideAttrs
  (oldAttrs: rec {
    pname = "omega-llama-cpp-mtp";
    version = "22673";

    src = fetchFromGitHub {
      owner = "am17an";
      repo = "llama.cpp";
      rev = "5d5f1b46e4f56885801c86363d4677a5f72f83af";
      hash = "sha256-lhWocJWRd49R+Xq47AovYXuORxlcoNCqUKfCU4iviHk=";
      leaveDotGit = true;
      postFetch = ''
        git -C "$out" rev-parse --short HEAD > $out/COMMIT
        find "$out" -name .git -print0 | xargs -0 rm -rf
      '';
    };

    npmDepsHash = "sha256-k62LIbyY2DXvs7XXbX0lNPiYxuYzeJUyQtS4eA+68f8=";

    postPatch = ''
      if [ -f tools/server/public/index.html.gz ]; then
        rm tools/server/public/index.html.gz
      fi
    '';

    cmakeFlags =
      lib.filter (flag: !(lib.hasPrefix "-DCMAKE_CUDA_ARCHITECTURES" flag)) (oldAttrs.cmakeFlags or [ ])
      ++ [ "-DCMAKE_CUDA_ARCHITECTURES=86" ];

    meta = oldAttrs.meta // {
      description = "llama.cpp with CUDA and MTP speculative decoding support for RTX 3090";
    };
  })
