# Qwen3.5 local run notes

Local notes for running Unsloth Qwen3.5 GGUFs on the Framework Desktop with the `framework-llama-cpp` package.

## Verified local model paths

These paths were checked on disk under `~/.local/share/llama-cpp/models`:

```bash
export MODELS="$HOME/.local/share/llama-cpp/models"

export M9="$MODELS/qwen3.5-9b/Qwen3.5-9B-UD-Q4_K_XL.gguf"
export M27="$MODELS/qwen3.5-27b/Qwen3.5-27B-UD-Q4_K_XL.gguf"
export M35="$MODELS/qwen3.5-35b-a3b/Qwen3.5-35B-A3B-UD-Q4_K_XL.gguf"
export M122="$MODELS/qwen3.5-122b-a10b/UD-Q4_K_XL/Qwen3.5-122B-A10B-UD-Q4_K_XL-00001-of-00003.gguf"
```

Verify them before running anything:

```bash
printf '9B=%s\n27B=%s\n35B=%s\n122B=%s\n' "$M9" "$M27" "$M35" "$M122"
ls -lh "$M9" "$M27" "$M35" "$M122"
```

`122B` is a sharded GGUF, so point `llama.cpp` at the **first shard**.

## Unsloth memory guidance

From Unsloth's Qwen3.5 usage guide:

| Model | 4-bit | 6-bit | 8-bit | BF16 |
| --- | ---: | ---: | ---: | ---: |
| Qwen3.5-9B | 6.5 GB | 9 GB | 13 GB | 19 GB |
| Qwen3.5-27B | 17 GB | 24 GB | 30 GB | 54 GB |
| Qwen3.5-35B-A3B | 22 GB | 30 GB | 38 GB | 70 GB |
| Qwen3.5-122B-A10B | 70 GB | 106 GB | 132 GB | 245 GB |

For this machine:

- `9B`, `27B`, `35B-A3B` should fit comfortably in Q4.
- `122B-A10B` Q4 is realistic on 128 GB unified memory, but start with smaller context sizes.
- Do not start `122B` at `262144` context. Start at `8192` or `16384`.

## Important Qwen3.5 llama.cpp notes

- Qwen3.5 max context: `262144`
- If output gets weird or gibberish:
  - raise context size, or
  - try `--cache-type-k bf16 --cache-type-v bf16`
- Small models (`0.8B`, `2B`, `4B`, `9B`) have thinking **disabled** by default.
  - enable it with `--chat-template-kwargs '{"enable_thinking":true}'`
- For larger models, disable thinking with:

```bash
--chat-template-kwargs '{"enable_thinking":false}'
```

Recommended sampling from Unsloth:

- Thinking, coding: `--temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 0.0`
- Thinking, general: `--temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.0 --presence-penalty 1.5`
- Non-thinking, general: `--temp 0.7 --top-p 0.8 --top-k 20 --min-p 0.0 --presence-penalty 1.5`

## Current host tuning

The Framework host is configured to use `pkgs.framework-llama-cpp` with:

- ROCm backend
- `gfx1151`
- `LLAMA_HIP_UMA=ON`
- wrapped binaries with default `ROCBLAS_USE_HIPBLASLT=1`
- `--n-gpu-layers 999`
- flash attention enabled in aliases
- `--no-mmap` in aliases

So the intended shape is: offload as much as possible and lean on UMA.

Because the overlay wraps the binaries with `ROCBLAS_USE_HIPBLASLT=1`, the commands below do not need an explicit `env ROCBLAS_USE_HIPBLASLT=1` prefix when using `framework-llama-cpp`.

## First check after rebuild

Before benchmarking, make sure the binary is new enough for Qwen3.5:

```bash
llama-cli -v --model "$M9" -n 1 -p test
```

If you still see:

```text
unknown model architecture: 'qwen35'
```

then the `llama.cpp` in the current build is still too old.

Also list devices once:

```bash
llama-bench --list-devices
```

## Local run order

Recommended progression:

1. `9B` smoke test
2. `27B` quality baseline
3. `35B-A3B` likely daily driver
4. `122B-A10B` big-model run

## Interactive runs

### 9B non-thinking

```bash
llama-cli \
  --model "$M9" \
  --ctx-size 16384 \
  --n-gpu-layers 999 \
  --flash-attn on \
  --no-mmap \
  --conversation \
  --temp 0.7 \
  --top-p 0.8 \
  --top-k 20 \
  --min-p 0.0 \
  --presence-penalty 1.5
```

### 9B thinking enabled

```bash
llama-cli \
  --model "$M9" \
  --ctx-size 16384 \
  --n-gpu-layers 999 \
  --flash-attn on \
  --no-mmap \
  --conversation \
  --chat-template-kwargs '{"enable_thinking":true}' \
  --temp 0.6 \
  --top-p 0.95 \
  --top-k 20 \
  --min-p 0.0 \
  --presence-penalty 0.0
```

### 27B thinking / coding-style settings

```bash
llama-cli \
  --model "$M27" \
  --ctx-size 16384 \
  --n-gpu-layers 999 \
  --flash-attn on \
  --no-mmap \
  --conversation \
  --temp 0.6 \
  --top-p 0.95 \
  --top-k 20 \
  --min-p 0.0 \
  --presence-penalty 0.0
```

### 35B-A3B thinking / coding-style settings

```bash
llama-cli \
  --model "$M35" \
  --ctx-size 16384 \
  --n-gpu-layers 999 \
  --flash-attn on \
  --no-mmap \
  --conversation \
  --temp 0.6 \
  --top-p 0.95 \
  --top-k 20 \
  --min-p 0.0 \
  --presence-penalty 0.0
```

### 35B-A3B non-thinking

```bash
llama-cli \
  --model "$M35" \
  --ctx-size 16384 \
  --n-gpu-layers 999 \
  --flash-attn on \
  --no-mmap \
  --conversation \
  --chat-template-kwargs '{"enable_thinking":false}' \
  --temp 0.7 \
  --top-p 0.8 \
  --top-k 20 \
  --min-p 0.0 \
  --presence-penalty 1.5
```

### 122B-A10B conservative first run

```bash
llama-cli \
  --model "$M122" \
  --ctx-size 8192 \
  --n-gpu-layers 999 \
  --flash-attn on \
  --no-mmap \
  --conversation \
  --chat-template-kwargs '{"enable_thinking":false}' \
  --temp 0.7 \
  --top-p 0.8 \
  --top-k 20 \
  --min-p 0.0 \
  --presence-penalty 1.5
```

Then try `--ctx-size 16384`, then `32768`.

If long-context behavior gets unstable, retry with:

```bash
--cache-type-k bf16 --cache-type-v bf16
```

## Local server

### 35B-A3B server

```bash
llama-server \
  --model "$M35" \
  --ctx-size 16384 \
  --n-gpu-layers 999 \
  --flash-attn on \
  --no-mmap \
  --host 0.0.0.0 \
  --port 8080 \
  --chat-template-kwargs '{"enable_thinking":false}'
```

### 122B-A10B server

```bash
llama-server \
  --model "$M122" \
  --ctx-size 8192 \
  --n-gpu-layers 999 \
  --flash-attn on \
  --no-mmap \
  --host 0.0.0.0 \
  --port 8080 \
  --chat-template-kwargs '{"enable_thinking":false}'
```

## Benchmark matrix

Use `llama-bench --list-devices` once before the first run.

### Short benchmark: `pp512 / tg128`

#### 9B

```bash
llama-bench \
  -m "$M9" \
  -p 512 \
  -n 128 \
  -b 2048 \
  -ub 512 \
  -ngl 999 \
  -fa 1 \
  -mmp 0 \
  -r 3 \
  -o md
```

#### 27B

```bash
llama-bench \
  -m "$M27" \
  -p 512 \
  -n 128 \
  -b 2048 \
  -ub 512 \
  -ngl 999 \
  -fa 1 \
  -mmp 0 \
  -r 3 \
  -o md
```

#### 35B-A3B

```bash
llama-bench \
  -m "$M35" \
  -p 512 \
  -n 128 \
  -b 2048 \
  -ub 512 \
  -ngl 999 \
  -fa 1 \
  -mmp 0 \
  -r 3 \
  -o md
```

#### 122B-A10B

```bash
llama-bench \
  -m "$M122" \
  -p 512 \
  -n 128 \
  -b 2048 \
  -ub 512 \
  -ngl 999 \
  -fa 1 \
  -mmp 0 \
  -r 3 \
  -o md
```

### Longer-context benchmark: `pp2048 / tg32 @ depth 32768`

#### 9B

```bash
llama-bench \
  -m "$M9" \
  -p 2048 \
  -n 32 \
  -d 32768 \
  -b 2048 \
  -ub 512 \
  -ngl 999 \
  -fa 1 \
  -mmp 0 \
  -r 3 \
  -o md
```

#### 27B

```bash
llama-bench \
  -m "$M27" \
  -p 2048 \
  -n 32 \
  -d 32768 \
  -b 2048 \
  -ub 512 \
  -ngl 999 \
  -fa 1 \
  -mmp 0 \
  -r 3 \
  -o md
```

#### 35B-A3B

```bash
llama-bench \
  -m "$M35" \
  -p 2048 \
  -n 32 \
  -d 32768 \
  -b 2048 \
  -ub 512 \
  -ngl 999 \
  -fa 1 \
  -mmp 0 \
  -r 3 \
  -o md
```

#### 122B-A10B

```bash
llama-bench \
  -m "$M122" \
  -p 2048 \
  -n 32 \
  -d 32768 \
  -b 2048 \
  -ub 512 \
  -ngl 999 \
  -fa 1 \
  -mmp 0 \
  -r 3 \
  -o md
```

### Stress test: larger prompt / deeper KV

#### 35B-A3B

```bash
llama-bench \
  -m "$M35" \
  -p 4096 \
  -n 32 \
  -d 65536 \
  -b 2048 \
  -ub 512 \
  -ngl 999 \
  -fa 1 \
  -mmp 0 \
  -r 2 \
  -o md
```

#### 122B-A10B

```bash
llama-bench \
  -m "$M122" \
  -p 4096 \
  -n 32 \
  -d 65536 \
  -b 2048 \
  -ub 512 \
  -ngl 999 \
  -fa 1 \
  -mmp 0 \
  -r 2 \
  -o md
```

If `122B` is unstable or too memory-hungry here, lower depth or move to a smaller quant.

## Save JSON benchmark output

### 35B short

```bash
llama-bench \
  -m "$M35" -p 512 -n 128 -b 2048 -ub 512 -ngl 999 -fa 1 -mmp 0 -r 3 -o json \
  > qwen35a3b-short.json
```

### 35B long

```bash
llama-bench \
  -m "$M35" -p 2048 -n 32 -d 32768 -b 2048 -ub 512 -ngl 999 -fa 1 -mmp 0 -r 3 -o json \
  > qwen35a3b-long.json
```

## Small helper script

```bash
mkdir -p "$HOME/llama-bench-results"

cat > "$HOME/llama-bench-results/bench-qwen35.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

MODELS="${MODELS:-$HOME/.local/share/llama-cpp/models}"
OUT="${OUT:-$HOME/llama-bench-results}"
mkdir -p "$OUT"

M9="$MODELS/qwen3.5-9b/Qwen3.5-9B-UD-Q4_K_XL.gguf"
M27="$MODELS/qwen3.5-27b/Qwen3.5-27B-UD-Q4_K_XL.gguf"
M35="$MODELS/qwen3.5-35b-a3b/Qwen3.5-35B-A3B-UD-Q4_K_XL.gguf"
M122="$MODELS/qwen3.5-122b-a10b/UD-Q4_K_XL/Qwen3.5-122B-A10B-UD-Q4_K_XL-00001-of-00003.gguf"

for model in "$M9" "$M27" "$M35" "$M122"; do
  [ -f "$model" ] || { echo "missing model: $model" >&2; exit 1; }
done

run_bench() {
  local name="$1"
  local model="$2"
  shift 2
  echo "==> $name"
  llama-bench "$@" -m "$model" -o json | tee "$OUT/$name.json"
}

run_bench qwen35-9b-short   "$M9"   -p 512  -n 128 -b 2048 -ub 512 -ngl 999 -fa 1 -mmp 0 -r 3
run_bench qwen35-27b-short  "$M27"  -p 512  -n 128 -b 2048 -ub 512 -ngl 999 -fa 1 -mmp 0 -r 3
run_bench qwen35-35b-short  "$M35"  -p 512  -n 128 -b 2048 -ub 512 -ngl 999 -fa 1 -mmp 0 -r 3
run_bench qwen35-122b-short "$M122" -p 512  -n 128 -b 2048 -ub 512 -ngl 999 -fa 1 -mmp 0 -r 3

run_bench qwen35-9b-long    "$M9"   -p 2048 -n 32  -d 32768 -b 2048 -ub 512 -ngl 999 -fa 1 -mmp 0 -r 3
run_bench qwen35-27b-long   "$M27"  -p 2048 -n 32  -d 32768 -b 2048 -ub 512 -ngl 999 -fa 1 -mmp 0 -r 3
run_bench qwen35-35b-long   "$M35"  -p 2048 -n 32  -d 32768 -b 2048 -ub 512 -ngl 999 -fa 1 -mmp 0 -r 3
run_bench qwen35-122b-long  "$M122" -p 2048 -n 32  -d 32768 -b 2048 -ub 512 -ngl 999 -fa 1 -mmp 0 -r 3
EOF

chmod +x "$HOME/llama-bench-results/bench-qwen35.sh"
```

Run it with:

```bash
"$HOME/llama-bench-results/bench-qwen35.sh"
```

## Practical recommendation

- Start with `9B` only as a smoke test.
- Use `35B-A3B` as the first serious daily-driver candidate.
- Use `27B` when you want a smaller quality baseline.
- Use `122B-A10B` as the biggest practical local model on this box.

## Troubleshooting

### `unknown model architecture: 'qwen35'`

Your `llama.cpp` build is still too old. Update `nixpkgs` or use a newer upstream `llama.cpp`.

### `failed to load model ...` but the file exists

Run the same command with `-v`. The generic error often hides the real cause.

### `122B` does not load

Make sure `-m` points to:

```bash
$MODELS/qwen3.5-122b-a10b/UD-Q4_K_XL/Qwen3.5-122B-A10B-UD-Q4_K_XL-00001-of-00003.gguf
```

not the directory and not shard `00002` or `00003`.

### Long-context output gets weird

Try:

```bash
--cache-type-k bf16 --cache-type-v bf16
```

and avoid starting at very high context sizes.
