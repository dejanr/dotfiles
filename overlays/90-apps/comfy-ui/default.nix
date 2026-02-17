{
  writeShellApplication,
  nix,
  gnugrep,
  comfy-ui-cuda,
}:
writeShellApplication {
  name = "comfy-ui";
  runtimeInputs = [
    nix
    gnugrep
  ];
  text = ''
    refs="$(nix-store -qR ${comfy-ui-cuda})"

    patterns=(
      'cuda_cudart-.*-lib$'
      'cuda_cudart-.*$'
      'cuda_cupti-.*-lib$'
      'libcublas-.*-lib$'
      'libcufft-.*-lib$'
      'libcurand-.*-lib$'
      'libcusolver-.*-lib$'
      'libcusparse-.*-lib$'
      'cudnn-.*-lib$'
      'nccl-.*$'
      'cuda_nvrtc-.*-lib$'
      'libnvjitlink-.*-lib$'
    )

    extra_ld=""
    for pattern in "''${patterns[@]}"; do
      match="$(grep -m1 "$pattern" <<< "$refs" || true)"
      if [[ -n "$match" ]]; then
        if [[ -d "$match/lib" ]]; then
          extra_ld="$extra_ld''${extra_ld:+:}$match/lib"
        elif [[ -d "$match/lib64" ]]; then
          extra_ld="$extra_ld''${extra_ld:+:}$match/lib64"
        fi
      fi
    done

    if [[ -n "$extra_ld" ]]; then
      export LD_LIBRARY_PATH="$extra_ld''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi

    exec ${comfy-ui-cuda}/bin/comfy-ui "$@"
  '';
}
