# shellcheck shell=bash

git_local_pattern() {
  local pattern=$1
  pattern=${pattern//\\/\\\\}
  pattern=${pattern//\*/\\*}
  pattern=${pattern//\?/\\?}
  pattern=${pattern//\[/\\[}
  pattern=${pattern//\]/\\]}
  pattern=${pattern// /\\ }
  printf '/%s\n' "$pattern"
}

git_local_decode_pattern() {
  local pattern=$1 remaining character decoded=''
  [[ $pattern == /* && $pattern != / ]] || return 1
  pattern=${pattern%/}
  remaining=${pattern#/}
  while [[ -n $remaining ]]; do
    character=${remaining:0:1}
    remaining=${remaining:1}
    if [[ $character == "\\" ]]; then
      [[ -n $remaining ]] || return 1
      character=${remaining:0:1}
      remaining=${remaining:1}
    fi
    decoded+=$character
  done
  [[ $(git_local_pattern "$decoded") == "$pattern" ]] || return 1
  printf '%s\n' "$decoded"
}

git_local_show() {
  local root=$1 exclude=$2 pattern path entry
  {
    if [[ -f $exclude ]]; then
      while IFS= read -r pattern || [[ -n $pattern ]]; do
        path=$(git_local_decode_pattern "$pattern") || continue
        realpath --canonicalize-missing --no-symlinks --relative-to="$PWD" -- "$root/$path"
      done < "$exclude"
    fi
    git -C "$root" ls-files -v -z | while IFS= read -r -d '' entry; do
      case "$entry" in
        S\ * | s\ *)
          path=${entry:2}
          if [[ $path == *$'\n'* || $path == *$'\r'* ]]; then
            echo 'Cannot list a skip-worktree path containing a newline or carriage return.' >&2
            return 1
          fi
          realpath --canonicalize-missing --no-symlinks --relative-to="$PWD" -- "$root/$path"
          ;;
      esac
    done
  } | LC_ALL=C sort -u
}

git_local_files() {
  local action=$1
  shift

  if [[ ${1:-} == --help || ${1:-} == -h ]]; then
    printf 'Usage: git-local-%s' "$action"
    if [[ $action != show ]]; then
      printf ' [--] <file-or-directory>...'
    fi
    printf '\n%s\n' 'Paths are literal and relative to the current directory; directories include tracked descendants.'
    printf '%s\n' 'git-local-show | git-local-restore restores listed paths without changing file contents.'
    printf '%s\n' 'Show lists literal root-anchored local exclude rules and skip-worktree paths, not global or wildcard ignore rules.'
    return 0
  fi

  if [[ $action == restore && $# -eq 0 && ! -t 0 ]]; then
    local input_path
    while IFS= read -r input_path || [[ -n $input_path ]]; do
      [[ -z $input_path ]] || set -- "$@" "$input_path"
    done
    [[ $# -gt 0 ]] || return 0
  fi

  if [[ $action == show ]]; then
    if [[ $# -gt 0 ]]; then
      echo 'Usage: git-local-show' >&2
      return 1
    fi
    local show_root show_exclude
    show_root=$(git rev-parse --show-toplevel)
    show_exclude=$(git rev-parse --git-path info/exclude)
    if [[ $(git config --bool core.sparseCheckout || true) == true ]]; then
      echo 'Refusing to list skip-worktree flags in a sparse checkout.' >&2
      return 1
    fi
    git_local_show "$show_root" "$show_exclude"
    return
  fi

  if [[ ${1:-} == -- ]]; then
    shift
  fi
  if [[ $# -eq 0 ]]; then
    echo 'Provide at least one file or directory.' >&2
    return 1
  fi

  local root path relative pattern exclude temporary status
  local paths=() patterns=() filters=()
  root=$(git rev-parse --show-toplevel)
  if [[ $(git config --bool core.sparseCheckout || true) == true ]]; then
    echo 'Refusing to change skip-worktree flags in a sparse checkout.' >&2
    return 1
  fi

  for path in "$@"; do
    relative=$(realpath --canonicalize-missing --no-symlinks --relative-to="$root" -- "$path")
    case "$relative" in
      . | .. | ../* | .git | .git/* | *$'\n'* | *$'\r'*)
        printf 'Not a supported path inside the working tree: %s\n' "$path" >&2
        return 1
        ;;
    esac
    paths+=("$relative")
    pattern=$(git_local_pattern "$relative")
    patterns+=("$pattern")
    filters+=(-e "$pattern" -e "$pattern/")
  done

  cd "$root" || return 1
  exclude=$(git rev-parse --git-path info/exclude)
  if [[ $action == ignore ]]; then
    mkdir -p "$(dirname "$exclude")"
    touch "$exclude"
    for pattern in "${patterns[@]}"; do
      if ! grep -qxF -e "$pattern" -e "$pattern/" "$exclude"; then
        printf '\n%s\n' "$pattern" >> "$exclude"
      fi
    done
    GIT_LITERAL_PATHSPECS=1 git ls-files -z -- "${paths[@]}" |
      git update-index --skip-worktree -z --stdin
    printf '%s\n' 'Local hiding enabled. Staged changes remain visible.'
    printf '%s\n' 'Run git-local-restore with the same paths before switching branches, merging, or pulling.'
  else
    GIT_LITERAL_PATHSPECS=1 git ls-files -z -- "${paths[@]}" |
      git update-index --no-skip-worktree -z --stdin
    if [[ -f "$exclude" ]]; then
      temporary=$(mktemp)
      status=0
      grep -vxF "${filters[@]}" "$exclude" > "$temporary" || status=$?
      if [[ $status -gt 1 ]]; then
        rm -f "$temporary"
        return "$status"
      fi
      cat "$temporary" > "$exclude"
      rm -f "$temporary"
    fi
    printf '%s\n' 'Matching local hiding removed. File contents are unchanged; other ignore rules may still apply.'
  fi
}
