{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "qwen36-mtp-server";
  runtimeInputs = [ pkgs.omega-llama-cpp-mtp pkgs.curl ];
  text = ''
    model="''${QWEN36_MTP_MODEL:-$HOME/.local/share/llama-cpp/models/Qwen3.6-27B-MTP-Q4_K_M.gguf}"
    if [ "$#" -gt 0 ]; then
      model="$1"
      shift
    fi

    # Download model if not present
    if [ ! -f "$model" ]; then
      echo "Model not found at: $model"
      echo "Downloading Qwen3.6-27B-MTP-Q4_K_M.gguf (~17 GB)..."
      mkdir -p "$(dirname "$model")"
      curl -L --progress-bar "https://huggingface.co/froggeric/Qwen3.6-27B-MTP-GGUF/resolve/main/Qwen3.6-27B-Q4_K_M-mtp.gguf" -o "$model"
      echo "Download complete."
    fi

    kv_dir="''${QWEN36_MTP_KV_DIR:-$HOME/.local/state/llama-cpp/kv_cache/qwen3.6-27b-mtp}"
    mkdir -p "$kv_dir"

    exec llama-server \
      --model "$model" \
      --alias qwen3.6-27b-mtp \
      --ctx-size "''${QWEN36_MTP_CTX:-100000}" \
      --host "''${QWEN36_MTP_HOST:-0.0.0.0}" \
      --port "''${QWEN36_MTP_PORT:-8181}" \
      --slot-save-path "$kv_dir" \
      --n-gpu-layers "''${QWEN36_MTP_NGL:-99}" \
      --flash-attn on \
      --cache-type-k q4_0 \
      --cache-type-v q4_0 \
      --spec-type mtp \
      --spec-draft-n-max "''${QWEN36_MTP_DRAFT:-2}" \
      --batch-size "''${QWEN36_MTP_BATCH:-2048}" \
      --ubatch-size "''${QWEN36_MTP_UBATCH:-512}" \
      --threads "''${QWEN36_MTP_THREADS:-8}" \
      --no-mmap \
      --prio 3 \
      --parallel 1 \
      --reasoning-format deepseek \
      --predict "''${QWEN36_MTP_PREDICT:-8192}" \
      --temp 0.8 \
      --top-p 0.95 \
      --top-k 40 \
      --min-p 0.05 \
      --repeat-penalty 1.1 \
      --metrics \
      "$@"
  '';
}
