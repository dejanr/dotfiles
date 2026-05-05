set -euo pipefail

from_tmux_option=false
if [ "${1:-}" = "--from-tmux-option" ]; then
  from_tmux_option=true
  shift
fi

if [ "$from_tmux_option" = true ]; then
  description="$(tmux show-option -gqv @new_worktree_description || true)"
  tmux set-option -gu @new_worktree_description >/dev/null 2>&1 || true
  start_dir="${1:-$PWD}"
else
  description="${1:-}"
  start_dir="${2:-$PWD}"
fi

message() {
  if [ -n "${TMUX:-}" ]; then
    tmux display-message "$*"
  else
    printf '%s\n' "$*"
  fi
}

fail() {
  message "$*"
  if [ "$from_tmux_option" = true ]; then
    exit 0
  fi
  exit 1
}

open_tmux_window() {
  if [ -n "${TMUX:-}" ]; then
    tmux new-window -c "$target_dir" -n "$window_name"
  fi
}

worktree_for_branch() {
  branch_ref="branch refs/heads/$branch"
  worktree_path=""

  while IFS= read -r line; do
    case "$line" in
      worktree\ *) worktree_path="${line#worktree }" ;;
      "$branch_ref")
        printf '%s\n' "$worktree_path"
        return 0
        ;;
      "") worktree_path="" ;;
    esac
  done < <(git -C "$repo_root" worktree list --porcelain)

  return 1
}

project_from_base() {
  base="$1"
  path="$2"
  case "$path" in
    "$base"/*)
      relative_path="${path#"$base"/}"
      printf '%s\n' "${relative_path%%/*}"
      return 0
      ;;
  esac
  return 1
}

slugify() {
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//; s/-{2,}/-/g'
}

[ -n "$description" ] || fail "Worktree idea cannot be empty"

if ! repo_root="$(git -C "$start_dir" rev-parse --show-toplevel 2>/dev/null)"; then
  fail "Not inside a git repository"
fi

repo_root="$(cd "$repo_root" && pwd -P)"
projects_dir="${PROJECTS_DIR:-$HOME/projects}"
worktrees_dir="${WORKTREES_DIR:-$HOME/worktrees}"

if [ -d "$projects_dir" ]; then
  projects_dir="$(cd "$projects_dir" && pwd -P)"
fi
mkdir -p "$worktrees_dir"
worktrees_dir="$(cd "$worktrees_dir" && pwd -P)"

if project="$(project_from_base "$projects_dir" "$repo_root")"; then
  :
elif project="$(project_from_base "$worktrees_dir" "$repo_root")"; then
  :
else
  project="$(basename "$repo_root")"
fi

slug="$(slugify "$description")"
[ -n "$slug" ] || fail "Worktree idea must contain letters or numbers"

branch_prefix="${WORKTREE_BRANCH_PREFIX:-feature}"
branch_prefix="${branch_prefix%/}"
if [ -n "$branch_prefix" ]; then
  branch="$branch_prefix/$slug"
else
  branch="$slug"
fi

target_dir="$worktrees_dir/$project/$slug"
window_name="$slug"

if existing_worktree="$(worktree_for_branch)"; then
  if [ -d "$existing_worktree" ]; then
    target_dir="$(cd "$existing_worktree" && pwd -P)"
    open_tmux_window
    message "Opened existing worktree: $target_dir"
    exit 0
  fi

  git -C "$repo_root" worktree prune
fi

if git -C "$target_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  open_tmux_window
  message "Opened existing worktree: $target_dir"
  exit 0
fi

[ ! -e "$target_dir" ] || fail "Target already exists: $target_dir"
mkdir -p "$(dirname "$target_dir")"

if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
  if ! output="$(git -C "$repo_root" worktree add "$target_dir" "$branch" 2>&1)"; then
    fail "git worktree add failed: $(printf '%s' "$output" | tr '\n' ' ')"
  fi
else
  if ! output="$(git -C "$repo_root" worktree add -b "$branch" "$target_dir" 2>&1)"; then
    fail "git worktree add failed: $(printf '%s' "$output" | tr '\n' ' ')"
  fi
fi

open_tmux_window
message "Created $branch at $target_dir"
