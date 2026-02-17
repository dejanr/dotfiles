{ pkgs }:
let
  curl = "${pkgs.curl}/bin/curl";
  jq = "${pkgs.jq}/bin/jq";
  journalctl = "${pkgs.systemd}/bin/journalctl";
  column = "${pkgs.util-linux}/bin/column";
  awk = "${pkgs.gawk}/bin/awk";
  sed = "${pkgs.gnused}/bin/sed";
  sort = "${pkgs.coreutils}/bin/sort";
  ls = "${pkgs.coreutils}/bin/ls";
  find = "${pkgs.findutils}/bin/find";
  head = "${pkgs.coreutils}/bin/head";
  basename = "${pkgs.coreutils}/bin/basename";
  cat = "${pkgs.coreutils}/bin/cat";
  mktemp = "${pkgs.coreutils}/bin/mktemp";
  date = "${pkgs.coreutils}/bin/date";
in
''
  #!/usr/bin/env bash
  set -euo pipefail

  BASE_URL="''${COMFYUI_URL:-http://127.0.0.1:8188}"
  MODE="''${COMFYUI_DB_MODE:-cache}"
  DATA_DIR="''${COMFYUI_DATA_DIR:-$HOME/.config/comfy-ui}"
  CACHE_DIR="$DATA_DIR/user/__manager/cache"

  usage() {
    cat <<'EOF'
  ComfyUI model CLI

  Usage:
    comfy-model search <query>
    comfy-model install <name-or-filename>
    comfy-model install-missing [since]
    comfy-model install-workflow <workflow.json>
    comfy-model download-url <url> <save_path> [filename]
    comfy-model missing [since]

  Environment:
    COMFYUI_URL       Base URL (default: http://127.0.0.1:8188)
    COMFYUI_DB_MODE   cache|local|remote
    COMFYUI_DATA_DIR  ComfyUI data dir (default: ~/.config/comfy-ui)

  Examples:
    comfy-model search pulid
    comfy-model install pulid_v1.1.safetensors
    comfy-model install-missing 6h
    comfy-model install-workflow ~/Downloads/workflow.json
    comfy-model download-url https://example.com/model.safetensors checkpoints
    comfy-model missing 2h
  EOF
  }

  api_get() {
    ${curl} -fsS "$1"
  }

  post_json() {
    local url="$1"
    local body="$2"
    local tmp status
    tmp="$(${mktemp})"
    status="$(${curl} -sS -o "$tmp" -w '%{http_code}' -X POST "$url" -H 'Content-Type: application/json' -d "$body")"

    if [[ "$status" -lt 200 || "$status" -ge 300 ]]; then
      echo "error: request failed ($status) $url" >&2
      ${cat} "$tmp" >&2
      rm -f "$tmp"
      return 1
    fi

    ${cat} "$tmp"
    rm -f "$tmp"
  }

  model_list_file() {
    local file
    file="$(${ls} -1t "$CACHE_DIR"/*_model-list.json 2>/dev/null | ${head} -1 || true)"
    if [[ -z "$file" ]]; then
      echo "error: model list cache not found in $CACHE_DIR" >&2
      echo "hint: open ComfyUI -> Manager once, then retry" >&2
      return 1
    fi
    printf '%s\n' "$file"
  }

  model_list_json() {
    local file
    file="$(model_list_file)"
    ${cat} "$file"
  }

  search_models() {
    local query="$1"
    model_list_json | ${jq} -r --arg q "''${query,,}" '
      .models[]
      | select(
          (.name // "" | ascii_downcase | contains($q))
          or (.filename // "" | ascii_downcase | contains($q))
          or (.type // "" | ascii_downcase | contains($q))
          or (.base // "" | ascii_downcase | contains($q))
          or (.save_path // "" | ascii_downcase | contains($q))
        )
      | [
          .name,
          .filename,
          .save_path,
          .type,
          (.base // ""),
          .installed
        ]
      | @tsv
    ' | ${column} -t -s $'\t'
  }

  resolve_model() {
    local query="$1"
    local matches count

    matches="$(model_list_json | ${jq} -c --arg q "''${query,,}" '
      [ .models[]
        | select((.filename // "" | ascii_downcase) == $q or (.name // "" | ascii_downcase) == $q)
      ]
    ')"

    if [[ "$(${jq} 'length' <<<"$matches")" -eq 0 ]]; then
      matches="$(model_list_json | ${jq} -c --arg q "''${query,,}" '
        [ .models[]
          | select(
              (.filename // "" | ascii_downcase | contains($q))
              or (.name // "" | ascii_downcase | contains($q))
            )
        ]
      ')"
    fi

    count="$(${jq} 'length' <<<"$matches")"

    if [[ "$count" -eq 0 ]]; then
      echo "error: no model found for query: $query" >&2
      return 1
    fi

    if [[ "$count" -gt 1 ]]; then
      echo "error: query is ambiguous ($count matches). Refine query." >&2
      ${jq} -r '.[] | [.name, .filename, .save_path, .installed] | @tsv' <<<"$matches" | ${column} -t -s $'\t' >&2
      return 1
    fi

    ${jq} -c '.[0]' <<<"$matches"
  }

  install_model() {
    local query="$1"
    local model payload client_id ui_id save_path filename target

    model="$(resolve_model "$query")" || {
      echo "skip: not found in manager model index: $query" >&2
      return 2
    }

    save_path="$(${jq} -r '.save_path // ""' <<<"$model")"
    filename="$(${jq} -r '.filename' <<<"$model")"
    target="$DATA_DIR/models/$save_path/$filename"

    if [[ -f "$target" ]]; then
      echo "Already installed: $target" >&2
      return 0
    fi

    client_id="cli-$(${date} +%s)"
    ui_id="cli-$(${date} +%s%N)"

    payload="$(${jq} -nc --argjson m "$model" --arg client_id "$client_id" --arg ui_id "$ui_id" '
      $m + {client_id:$client_id, ui_id:$ui_id}
    ')"

    post_json "''${BASE_URL}/v2/manager/queue/install_model" "$payload" >/dev/null || return 1

    echo "Queued install for: $(${jq} -r '.name' <<<"$model")" >&2
    echo "Target: $target" >&2
    echo "Check queue status:" >&2
    echo "  ${curl} -s ''${BASE_URL}/v2/manager/queue/status | ${jq}" >&2
  }

  basename_from_url() {
    local url="$1"
    local no_query="''${url%%\?*}"
    ${basename} "$no_query"
  }

  download_url() {
    local url="$1"
    local folder="$2"
    local filename="''${3:-$(basename_from_url "$url")}"

    local payload response download_id progress status percent
    payload="$(${jq} -nc --arg url "$url" --arg folder "$folder" --arg filename "$filename" '{url:$url, folder:$folder, filename:$filename}')"

    response="$(post_json "''${BASE_URL}/api/download-model" "$payload")"
    echo "$response" | ${jq}

    download_id="$(${jq} -r '.download_id // empty' <<<"$response")"
    if [[ -z "$download_id" ]]; then
      return 0
    fi

    echo "Tracking download: $download_id" >&2
    while true; do
      progress="$(api_get "''${BASE_URL}/api/download-progress/$download_id" || true)"
      status="$(${jq} -r '.download.status // empty' <<<"$progress")"
      percent="$(${jq} -r '.download.percent // 0' <<<"$progress")"

      if [[ -n "$status" ]]; then
        printf "\rstatus=%s percent=%s%%" "$status" "$percent" >&2
      fi

      if [[ "$status" == "completed" ]]; then
        echo >&2
        echo "Download completed." >&2
        break
      fi

      if [[ "$status" == "error" ]]; then
        echo >&2
        echo "Download failed:" >&2
        echo "$progress" | ${jq} >&2
        return 1
      fi

      sleep 1
    done
  }

  normalize_since() {
    local raw="$1"
    if [[ "$raw" =~ ^([0-9]+)([smhd])$ ]]; then
      local n="''${BASH_REMATCH[1]}"
      local u="''${BASH_REMATCH[2]}"
      case "$u" in
        s) echo "$n seconds ago" ;;
        m) echo "$n minutes ago" ;;
        h) echo "$n hours ago" ;;
        d) echo "$n days ago" ;;
      esac
      return
    fi
    echo "$raw"
  }

  missing_entries_tsv() {
    local since_raw="''${1:-2h}"
    local since
    since="$(normalize_since "$since_raw")"

    ${journalctl} -u comfyui --since "$since" --no-pager \
      | ${sed} -n 's#.*Failed to find \(.*\/models\/.*\)\.$#\1#p' \
      | ${sed} 's#^.*/models/##' \
      | ${sed} -E 's#^(.+)/([^/]+)$#\1\t\2#' \
      | ${sort} -u
  }

  show_missing() {
    local since_raw="''${1:-2h}"
    missing_entries_tsv "$since_raw" | ${column} -t -s $'\t'
  }

  known_url_for_missing() {
    local path="$1"
    local filename="$2"

    case "$path/$filename" in
      "annotators/hr16/yolox-onnx/yolox_l.torchscript.pt")
        echo "https://huggingface.co/hr16/yolox-onnx/resolve/main/yolox_l.torchscript.pt"
        ;;
      "annotators/hr16/DWPose-TorchScript-BatchSize5/dw-ll_ucoco_384_bs5.torchscript.pt")
        echo "https://huggingface.co/hr16/DWPose-TorchScript-BatchSize5/resolve/main/dw-ll_ucoco_384_bs5.torchscript.pt"
        ;;
      *)
        return 1
        ;;
    esac
  }

  download_raw_to_models_path() {
    local url="$1"
    local rel_path="$2"
    local filename="$3"
    local target_dir target_file

    target_dir="$DATA_DIR/models/$rel_path"
    target_file="$target_dir/$filename"

    mkdir -p "$target_dir"
    echo "direct download -> $target_file" >&2
    ${curl} -fL "$url" -o "$target_file" --progress-bar
  }

  install_missing() {
    local since_raw="''${1:-2h}"
    local path filename url
    local failed=0

    while IFS=$'\t' read -r path filename; do
      [[ -n "$filename" ]] || continue
      echo "==> trying: $filename" >&2

      if install_model "$filename"; then
        continue
      fi

      if url="$(known_url_for_missing "$path" "$filename" 2>/dev/null)"; then
        echo "fallback: known URL found" >&2
        if download_raw_to_models_path "$url" "$path" "$filename"; then
          echo "downloaded: $path/$filename" >&2
          continue
        fi
      fi

      echo "note: unresolved in manager index (path: $path)." >&2
      echo "      use: comfy-model download-url <url> <save_path> <filename>" >&2
      echo "      or : comfy-model download-url <url> checkpoints $filename" >&2
      failed=1
    done < <(missing_entries_tsv "$since_raw")

    return "$failed"
  }

  extract_workflow_models() {
    local workflow="$1"
    ${jq} -r '.. | strings | select(test("\\.(safetensors|ckpt|pt|pt2|pth|bin|onnx|gguf|pkl)$"; "i"))' "$workflow" \
      | ${awk} -F'/' '{print $NF}' \
      | ${sort} -u
  }

  is_model_present() {
    local filename="$1"
    local found
    found="$(${find} "$DATA_DIR/models" -type f -name "$filename" -print -quit 2>/dev/null || true)"
    [[ -n "$found" ]]
  }

  known_source_for_filename() {
    local filename="$1"
    case "$filename" in
      "ema_vae_fp16.safetensors")
        echo "seedvr2|https://huggingface.co/numz/SeedVR2_comfyUI/resolve/main/ema_vae_fp16.safetensors"
        ;;
      "seedvr2_ema_7b-Q8_K_M.gguf")
        echo "seedvr2|https://huggingface.co/hk6668/SeedVR2-GGUF/resolve/main/seedvr2_ema_7b-Q8_K_M.gguf"
        ;;
      "qwen_3_8b.safetensors")
        echo "text_encoders|https://huggingface.co/Comfy-Org/flux2-klein-9B/resolve/main/split_files/text_encoders/qwen_3_8b.safetensors"
        ;;
      "new_flux-2-klein-9b.safetensors")
        echo "diffusion_models|https://huggingface.co/black-forest-labs/FLUX.2-klein-9B/resolve/main/flux-2-klein-9b.safetensors"
        ;;
      "flux-2-klein-4b.safetensors")
        echo "diffusion_models|https://huggingface.co/Comfy-Org/flux2-klein-4B/resolve/main/split_files/diffusion_models/flux-2-klein-4b.safetensors"
        ;;
      "qwen_3_4b.safetensors")
        echo "text_encoders|https://huggingface.co/Comfy-Org/flux2-klein-4B/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors"
        ;;
      *)
        return 1
        ;;
    esac
  }

  install_workflow() {
    local workflow="$1"
    local filename source folder url
    local failed=0

    if [[ ! -f "$workflow" ]]; then
      echo "error: workflow file not found: $workflow" >&2
      return 1
    fi

    while IFS= read -r filename; do
      [[ -n "$filename" ]] || continue

      if is_model_present "$filename"; then
        echo "present: $filename" >&2
        continue
      fi

      echo "==> workflow model: $filename" >&2
      if install_model "$filename"; then
        continue
      fi

      if source="$(known_source_for_filename "$filename" 2>/dev/null)"; then
        folder="''${source%%|*}"
        url="''${source#*|}"
        echo "fallback: known source -> $folder" >&2
        if download_url "$url" "$folder" "$filename"; then
          continue
        fi
      fi

      echo "note: unresolved from workflow: $filename" >&2
      failed=1
    done < <(extract_workflow_models "$workflow")

    return "$failed"
  }

  main() {
    local cmd="''${1:-}"
    case "$cmd" in
      search)
        [[ $# -ge 2 ]] || { usage; exit 1; }
        search_models "$2"
        ;;
      install)
        [[ $# -ge 2 ]] || { usage; exit 1; }
        install_model "$2"
        ;;
      install-missing)
        install_missing "''${2:-2h}"
        ;;
      install-workflow)
        [[ $# -ge 2 ]] || { usage; exit 1; }
        install_workflow "$2"
        ;;
      download-url)
        [[ $# -ge 3 ]] || { usage; exit 1; }
        download_url "$2" "$3" "''${4:-}"
        ;;
      missing)
        show_missing "''${2:-2h}"
        ;;
      -h|--help|help|"")
        usage
        ;;
      *)
        echo "error: unknown command '$cmd'" >&2
        usage
        exit 1
        ;;
    esac
  }

  main "$@"
''
