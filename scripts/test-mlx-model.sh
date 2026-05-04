#!/usr/bin/env bash

set -euo pipefail

mode="generate"
model="mlx-community/DeepSeek-V4-Flash-2bit-DQ"
prompt="In 3 short bullets, explain what MLX is."
system_prompt=""
max_tokens=""
temp=0.2
max_kv_size=""
kv_bits=""
kv_group_size=64
quantized_kv_start=""
aggressive_mode=0
trust_remote_code=0
setup_only=0
backend="auto"
venv_path="${HOME}/.cache/mlx-lm-deepseek-v4-venv"
hf_home="${HF_HOME:-}"
mlx_version="0.31.2"
mlx_lm_git_ref="git+https://github.com/machiabeli/mlx-lm-1@7d20c1d63a8290a025a122fa49a971381dded560"
server_host="127.0.0.1"
server_port=18080
server_log_level="INFO"
decode_concurrency=""
prompt_concurrency=""
prefill_step_size=""
prompt_cache_size=""
prompt_cache_bytes=""
chat_template_args=""

print_usage() {
  cat <<'EOF'
Usage:
  scripts/test-mlx-model.sh [options] [prompt...]
  scripts/test-mlx-model.sh <generate|chat|server|setup> [options] [prompt...]

Modes:
  generate    One-shot local generation (default)
  chat        Interactive local chat
  server      Run a local OpenAI-compatible MLX server for pi-mono
  setup       Prepare the selected backend and exit

General options:
  --model <repo-or-path>       Model repo or local path
  --hf-home <path>             Hugging Face cache directory
  --backend <auto|nix|metal-venv>
                               Backend to use. auto picks metal-venv for DeepSeek-V4.
  --venv-path <path>           Python venv path for the metal-venv backend
  --trust-remote-code          Pass through to mlx_lm
  --setup-only                 Prepare the backend and exit
  -h, --help                   Show this help

Generate/chat options:
  --prompt <text>              Prompt for generate mode
  --system-prompt <text>       System prompt for generate/chat mode
  --max-tokens <n>             Max generated tokens
  --temp <value>               Sampling temperature
  --max-kv-size <n>            KV cache size limit
  --kv-bits <n>                KV cache quantization bits
  --kv-group-size <n>          KV cache quantization group size
  --quantized-kv-start <n>     Start KV quantization from this step onward
  --aggressive                 Add activation quantization in generate mode
  --chat                       Alias for chat mode

Server options:
  --host <host>                Server host (default: 127.0.0.1)
  --port <port>                Server port (default: 18080)
  --log-level <level>          Server log level (default: INFO)
  --decode-concurrency <n>     Parallel decode requests
  --prompt-concurrency <n>     Parallel prompt requests
  --prefill-step-size <n>      Prefill step size
  --prompt-cache-size <n>      Prompt cache entry limit
  --prompt-cache-bytes <n>     Prompt cache byte limit
  --chat-template-args <json>  JSON passed to mlx_lm.server apply_chat_template

Examples:
  scripts/test-mlx-model.sh generate --system-prompt "Always respond in English." --prompt "Write a fibonacci function in TypeScript"
  scripts/test-mlx-model.sh chat --system-prompt "Always respond in English."
  scripts/test-mlx-model.sh server
  scripts/test-mlx-model.sh server --port 18080 --max-tokens 16384
  scripts/test-mlx-model.sh setup --backend metal-venv
EOF
}

require_value() {
  if [[ $# -lt 2 || -z ${2:-} ]]; then
    echo "Missing value for $1" >&2
    exit 1
  fi
}

resolve_backend() {
  if [[ "$backend" != "auto" ]]; then
    printf '%s\n' "$backend"
    return
  fi

  if [[ "$model" == "mlx-community/DeepSeek-V4-Flash-2bit-DQ" ]]; then
    printf '%s\n' "metal-venv"
  else
    printf '%s\n' "nix"
  fi
}

ensure_hf_home() {
  if [[ -n "$hf_home" ]]; then
    mkdir -p "$hf_home"
    export HF_HOME="$hf_home"
  fi
}

ensure_metal_venv() {
  if [[ ! -x /usr/bin/python3 ]]; then
    echo "/usr/bin/python3 is required for the metal-venv backend." >&2
    exit 1
  fi

  if [[ -x "$venv_path/bin/mlx_lm.generate" && -x "$venv_path/bin/mlx_lm.server" ]]; then
    return
  fi

  mkdir -p "$(dirname "$venv_path")"
  /usr/bin/python3 -m venv "$venv_path"
  # shellcheck disable=SC1090
  source "$venv_path/bin/activate"
  python -m ensurepip --upgrade >/dev/null
  python -m pip install --upgrade pip setuptools wheel
  python -m pip install "mlx==${mlx_version}" "$mlx_lm_git_ref"
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    generate|chat|server|setup)
      mode="$1"
      shift
      ;;
  esac
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)
      require_value "$@"
      model="$2"
      shift 2
      ;;
    --prompt)
      require_value "$@"
      prompt="$2"
      shift 2
      ;;
    --system-prompt)
      require_value "$@"
      system_prompt="$2"
      shift 2
      ;;
    --max-tokens)
      require_value "$@"
      max_tokens="$2"
      shift 2
      ;;
    --temp)
      require_value "$@"
      temp="$2"
      shift 2
      ;;
    --max-kv-size)
      require_value "$@"
      max_kv_size="$2"
      shift 2
      ;;
    --kv-bits)
      require_value "$@"
      kv_bits="$2"
      shift 2
      ;;
    --kv-group-size)
      require_value "$@"
      kv_group_size="$2"
      shift 2
      ;;
    --quantized-kv-start)
      require_value "$@"
      quantized_kv_start="$2"
      shift 2
      ;;
    --hf-home)
      require_value "$@"
      hf_home="$2"
      shift 2
      ;;
    --backend)
      require_value "$@"
      backend="$2"
      shift 2
      ;;
    --venv-path)
      require_value "$@"
      venv_path="$2"
      shift 2
      ;;
    --host)
      require_value "$@"
      server_host="$2"
      shift 2
      ;;
    --port)
      require_value "$@"
      server_port="$2"
      shift 2
      ;;
    --log-level)
      require_value "$@"
      server_log_level="$2"
      shift 2
      ;;
    --decode-concurrency)
      require_value "$@"
      decode_concurrency="$2"
      shift 2
      ;;
    --prompt-concurrency)
      require_value "$@"
      prompt_concurrency="$2"
      shift 2
      ;;
    --prefill-step-size)
      require_value "$@"
      prefill_step_size="$2"
      shift 2
      ;;
    --prompt-cache-size)
      require_value "$@"
      prompt_cache_size="$2"
      shift 2
      ;;
    --prompt-cache-bytes)
      require_value "$@"
      prompt_cache_bytes="$2"
      shift 2
      ;;
    --chat-template-args)
      require_value "$@"
      chat_template_args="$2"
      shift 2
      ;;
    --setup-only)
      setup_only=1
      shift
      ;;
    --aggressive)
      aggressive_mode=1
      shift
      ;;
    --trust-remote-code)
      trust_remote_code=1
      shift
      ;;
    --chat)
      mode="chat"
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    --)
      shift
      if [[ $# -gt 0 ]]; then
        prompt="$*"
      fi
      break
      ;;
    *)
      prompt="$*"
      break
      ;;
  esac
done

if [[ "$mode" == "setup" ]]; then
  setup_only=1
fi

selected_backend="$(resolve_backend)"
ensure_hf_home

if [[ -z "$max_tokens" ]]; then
  case "$mode" in
    generate)
      max_tokens=96
      ;;
    chat)
      max_tokens=4096
      ;;
    server)
      max_tokens=16384
      ;;
  esac
fi

if [[ "$mode" == "server" ]]; then
  if [[ -z "$decode_concurrency" ]]; then
    decode_concurrency=1
  fi
  if [[ -z "$prompt_concurrency" ]]; then
    prompt_concurrency=1
  fi
  if [[ -z "$prompt_cache_size" ]]; then
    prompt_cache_size=8
  fi
  if [[ -z "$prompt_cache_bytes" ]]; then
    prompt_cache_bytes=17179869184
  fi
fi

echo "Model: $model"
echo "Mode: $mode"
echo "Backend: $selected_backend"
if [[ -n ${HF_HOME:-} ]]; then
  echo "HF_HOME: $HF_HOME"
fi
if [[ "$model" == "mlx-community/DeepSeek-V4-Flash-2bit-DQ" ]]; then
  echo "Expected download size: about 90 GiB"
fi

case "$selected_backend" in
  metal-venv)
    ensure_metal_venv
    generate_bin="$venv_path/bin/mlx_lm.generate"
    chat_bin="$venv_path/bin/mlx_lm.chat"
    server_bin="$venv_path/bin/mlx_lm.server"
    ;;
  nix)
    if ! command -v mlx_lm.generate >/dev/null 2>&1 || ! command -v mlx_lm.server >/dev/null 2>&1; then
      echo "mlx_lm tools are not on PATH." >&2
      echo "Rebuild first with: nix run nix-darwin -- switch --flake .#mbp-work" >&2
      exit 1
    fi
    generate_bin="$(command -v mlx_lm.generate)"
    chat_bin="$(command -v mlx_lm.chat)"
    server_bin="$(command -v mlx_lm.server)"

    if [[ "$model" == "mlx-community/DeepSeek-V4-Flash-2bit-DQ" ]]; then
      echo "Warning: nixpkgs mlx is CPU-only here, so this model is unlikely to be practical with backend=nix." >&2
    fi
    ;;
  *)
    echo "Unknown backend: $selected_backend" >&2
    exit 1
    ;;
esac

if [[ $setup_only -eq 1 ]]; then
  echo "Backend is ready."
  exit 0
fi

if [[ -n "$kv_bits" && "$model" == "mlx-community/DeepSeek-V4-Flash-2bit-DQ" ]]; then
  echo "Warning: DeepSeek-V4 currently uses rotating/compressed caches, so KV quantization may fail." >&2
fi

case "$mode" in
  generate)
    command=(
      "$generate_bin"
      --model "$model"
      --prompt "$prompt"
      --max-tokens "$max_tokens"
      --temp "$temp"
      --verbose True
    )

    if [[ -n "$system_prompt" ]]; then
      command+=(--system-prompt "$system_prompt")
    fi

    if [[ -n "$max_kv_size" ]]; then
      command+=(--max-kv-size "$max_kv_size")
    fi

    if [[ -n "$kv_bits" ]]; then
      command+=(--kv-bits "$kv_bits" --kv-group-size "$kv_group_size")
      if [[ -n "$quantized_kv_start" ]]; then
        command+=(--quantized-kv-start "$quantized_kv_start")
      fi
    fi

    if [[ $aggressive_mode -eq 1 ]]; then
      command+=(--quantize-activations)
    fi
    ;;
  chat)
    command=(
      "$chat_bin"
      --model "$model"
      --max-tokens "$max_tokens"
      --temp "$temp"
    )

    if [[ -n "$system_prompt" ]]; then
      command+=(--system-prompt "$system_prompt")
    fi

    if [[ -n "$max_kv_size" ]]; then
      command+=(--max-kv-size "$max_kv_size")
    fi
    ;;
  server)
    if [[ -n "$system_prompt" ]]; then
      echo "Warning: --system-prompt is ignored in server mode; pi-mono will send its own system prompt." >&2
    fi

    command=(
      "$server_bin"
      --model "$model"
      --host "$server_host"
      --port "$server_port"
      --log-level "$server_log_level"
      --max-tokens "$max_tokens"
    )

    if [[ -n "$decode_concurrency" ]]; then
      command+=(--decode-concurrency "$decode_concurrency")
    fi

    if [[ -n "$prompt_concurrency" ]]; then
      command+=(--prompt-concurrency "$prompt_concurrency")
    fi

    if [[ -n "$prefill_step_size" ]]; then
      command+=(--prefill-step-size "$prefill_step_size")
    fi

    if [[ -n "$prompt_cache_size" ]]; then
      command+=(--prompt-cache-size "$prompt_cache_size")
    fi

    if [[ -n "$prompt_cache_bytes" ]]; then
      command+=(--prompt-cache-bytes "$prompt_cache_bytes")
    fi

    if [[ -n "$chat_template_args" ]]; then
      command+=(--chat-template-args "$chat_template_args")
    fi
    ;;
  *)
    echo "Unknown mode: $mode" >&2
    exit 1
    ;;
esac

if [[ $trust_remote_code -eq 1 ]]; then
  command+=(--trust-remote-code)
fi

printf 'Running: '
printf '%q ' "${command[@]}"
printf '\n'

exec "${command[@]}"
