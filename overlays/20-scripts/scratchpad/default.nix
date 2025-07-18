{ pkgs, ... }:

pkgs.writeShellApplication {
  name = "scratchpad";

  runtimeInputs = with pkgs; [
    tmux
    neovim
    coreutils
  ];

  text = ''
    SCRATCHPAD_DIR="$HOME/archive/dejli-scratchpad"
    SCRATCHPAD_FILE="$SCRATCHPAD_DIR/$(date +%y%m%d_%a).md"
    SESSION_NAME="scratchpad"

    create_session() {
      mkdir -p "$SCRATCHPAD_DIR"

      if [[ ! -f "$SCRATCHPAD_FILE" ]]; then
        echo "## $(date +%a)" > "$SCRATCHPAD_FILE"
      fi

      tmux new-session -s "$SESSION_NAME" -d
      tmux send-keys -t "$SESSION_NAME" "nvim '$SCRATCHPAD_FILE'" Enter

      if [[ -z "''${TMUX:-}" ]]; then
        tmux attach-session -t "$SESSION_NAME"
      else
        tmux switch-client -t "$SESSION_NAME"
      fi
    }

    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
      if [[ -z "''${TMUX:-}" ]]; then
        tmux attach-session -t "$SESSION_NAME"
      else
        tmux switch-client -t "$SESSION_NAME"
      fi
    else
      create_session
    fi
  '';
}
