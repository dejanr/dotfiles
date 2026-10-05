# ps-kill

Enable in your Home Manager host configuration:

```nix
modules.home.cli.ps-kill.enable = true;
```

The module installs the command and adds Ctrl+K integration to enabled Bash and
Zsh shells. It does not enable either shell itself. Disabling the module removes
the command and its bindings.

Run `ps-kill "node"` (or `sudo ps-kill "node"`) to search process commands with
fzf. The optional argument is the initial query, which you can edit.
Matching is exact and case-sensitive: `node` matches the lowercase substring,
not scattered letters or `Node`.
Run `ps-kill` or `ps-kill ""` to start with all selectable processes.
The picker keeps PID and owner visible and shortens executable/Nix paths.
The wrapped details pane shows CPU/memory usage, elapsed time, and the full
unmodified command. Ctrl+P toggles the details pane.
The picker starts in insert mode with a `ps-kill [INSERT]>` search prompt.
Escape switches to normal mode, hides query input to prevent accidental edits,
and changes the border label to `ps-kill [NORMAL]`. In normal mode:

- `j`/`k` move down/up; `g`/`G` jump to the first/last match.
- `i` or `/` returns to insert mode, preserving the query.
- `q` cancels. Ctrl+C cancels from either mode without sudo.

Ctrl+D/Ctrl+U move down/up half a page in either mode.
Enter immediately sends SIGKILL (`kill -9`) to the selected process and its
descendants, without confirmation. This bypasses cleanup and may lose unsaved data.
Enter with no matches cancels without sudo.

Ctrl+K opens the unfiltered picker at Bash and Zsh prompts, including shells
inside tmux. It preserves your current command line and replaces the default
kill-line shortcut. The binding is shell-local, so it does not intercept Ctrl+K
in editors or other running applications.

Non-root invocations authenticate with sudo after selection if needed.
The command prints the targets and sends SIGKILL, children first; it does not
target parents or kill other processes merely sharing the same name.
PID 1, the command itself, and its ancestors (including your shell) are protected.
Processes that exited or whose start time changed are skipped. Descendants spawned
after the target list was collected are not included. Services managed by a
supervisor may restart; use the service manager to stop those persistently.

Available on Linux and macOS.
Before rebuilding, run `bash modules/home/cli/ps-kill/ps-kill.sh "node"`
from this repository.
