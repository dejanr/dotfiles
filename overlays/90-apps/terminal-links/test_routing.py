#!/usr/bin/env python3
import argparse
from contextlib import contextmanager
import json
import os
from pathlib import Path
import pwd
import re
import shlex
import shutil
import signal
import socket
import subprocess
import tempfile
import time

REPO = Path(__file__).resolve().parents[3]
WEB_URLS = [
    "https://google.com/",
    "https://example.com/path?q=a%20b&literal=%27#fragment",
    "http://example.com/",
    "HTTPS://example.com/case",
]


def run(*args, env=None, check=True):
    return subprocess.run(args, env=env, check=check, capture_output=True,
                          text=True, timeout=10).stdout.strip()


def wait_for(check, description, timeout=8):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if value := check():
            return value
        time.sleep(0.05)
    raise AssertionError(f"Timed out: {description}")


@contextmanager
def process(command, env, log, pass_fds=()):
    child = subprocess.Popen(command, env=env, stdout=log, stderr=log,
                             pass_fds=pass_fds, start_new_session=True)
    try:
        yield child
    finally:
        try:
            os.killpg(child.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
        try:
            child.wait(timeout=5)
        except subprocess.TimeoutExpired:
            os.killpg(child.pid, signal.SIGKILL)
            child.wait()


def hyperlink(url, label):
    return f"\033]8;;{url}\033\\{label}\033]8;;\033\\"


def click(env, window, x, y, modified=True):
    if modified:
        run("xdotool", "keydown", "ctrl", "shift", env=env)
    try:
        run("xdotool", "mousemove", "--window", window, str(x), str(y), env=env)
        time.sleep(0.15)
        run("xdotool", "click", "1", env=env)
    finally:
        if modified:
            run("xdotool", "keyup", "shift", "ctrl", env=env)


def check_case(args, root, terminal, transport, base_env, ssh):
    root.mkdir(mode=0o700)
    for name in ("run", "bin", "config"):
        (root / name).mkdir(mode=0o700)
    env = base_env | {
        "HOME": str(root), "XDG_CONFIG_HOME": str(root / "config"),
        "XDG_DATA_HOME": str(root / "data"), "XDG_CACHE_HOME": str(root / "cache"),
        "XDG_RUNTIME_DIR": str(root / "run"), "TMPDIR": str(root),
        "PATH": str(root / "bin") + ":" + base_env["PATH"], "BROWSER_SIDE": "local",
    }
    if terminal == "monstar":
        env["TERMINFO"] = str(Path(args.monstar).resolve().parents[1] / "share/terminfo")
    browser_log = root / "browser.log"
    stub = root / "bin" / "xdg-open"
    stub.write_text("#!/bin/sh\nprintf '%s\\t%s\\t%s\\n' \"$BROWSER_SIDE\" \"$#\" \"$1\" >> "
                    + shlex.quote(str(browser_log)) + "\n")
    stub.chmod(0o700)

    def opened():
        return browser_log.read_text().splitlines() if browser_log.exists() else []

    target = root / "a'b file.txt"
    target.write_text("example text\n" * 80)
    file_url = target.as_uri() + "#L49C2"
    lines = [
        hyperlink(file_url, "FILE_LINK"),
        hyperlink(WEB_URLS[0], "HTTPS_LINK"), WEB_URLS[1],
        hyperlink(WEB_URLS[2], "HTTP_LINK"), hyperlink(WEB_URLS[3], "UPPERCASE_LINK"),
        hyperlink("javascript:alert(1)", "UNSUPPORTED_SCHEME"),
        hyperlink(file_url, "https://not-the-destination.example/"),
        "PLAIN_TEXT",
        hyperlink(WEB_URLS[0], "WRAPPED_" + "x" * 100),
    ]
    emitter = root / "emit.sh"
    emitter.write_text("#!/bin/sh\nprintf %s " + shlex.quote("\033[2J\033[H" + "\n".join(lines) + "\n")
                       + "\nsleep 120\n")
    config = root / "tmux.conf"
    handler = shlex.quote(args.opener) + " #{q:mouse_pane} #{q:mouse_hyperlink}"
    config.write_text("set -g mouse on\nset -g mouse-hyperlink-hover on\nset -g status off\n"
                      "set -as terminal-features ',xterm*:hyperlinks,monstar:hyperlinks'\n"
                      "bind -T root MouseDown1Pane if-shell -F '#{mouse_hyperlink}' {\n"
                      "  run-shell -b " + json.dumps(handler) + "\n} {\n"
                      "  select-pane -t =\n  send-keys -M\n}\n"
                      "bind -T root C-S-MouseUp1Pane if-shell -F '#{mouse_hyperlink}' {\n"
                      "  run-shell -b " + json.dumps(handler) + "\n}\n")
    command = [args.tmux, "-S", str(root / "tmux.sock")]

    def tmux(*options, check=True):
        return run(*command, *options, env=env, check=check)

    editor = str(root / "nvim.target.0")
    decoy = str(root / "nvim.decoy.0")
    expression = "json_encode([expand('%:p'), line('.'), col('.')])"

    def editor_state(server):
        return json.loads(run(args.nvim, "--server", server, "--remote-expr", expression, env=env))

    try:
        run(*command, "-f", str(config), "new-session", "-d", "-s", "probe", "sh", str(emitter),
            env=env | {"BROWSER_SIDE": "remote"})
        tmux("new-window", "-d", "-t", "probe", "-n", "editor",
             args.nvim, "--headless", "-u", "NONE", "--listen", editor)
        tmux("new-session", "-d", "-s", "decoy", args.nvim, "--headless", "-u", "NONE", "--listen", decoy)
        wait_for(lambda: Path(editor).exists() and Path(decoy).exists(), "Neovim sockets")
        attach = command + ["attach", "-t", "probe"]
        if transport == "ssh":
            attach = ssh + [shlex.join(["env", "-u", "TMUX", "-u", "TMUX_PANE",
                                      "TMPDIR=" + env["TMPDIR"], "XDG_RUNTIME_DIR=" + env["XDG_RUNTIME_DIR"],
                                      "TERMINFO=" + env.get("TERMINFO", "")] + attach)]
        title = f"routing-{terminal}-{transport}"
        if terminal == "kitty":
            kitty_config = root / "kitty.conf"
            mouse_maps = "\n".join(line.strip() for line in
                                   (REPO / "modules/home/gui/kitty/config.nix").read_text().splitlines()
                                   if line.strip().startswith("mouse_map "))
            kitty_config.write_text("linux_display_server x11\nfont_size 14\nwindow_padding_width 0\n"
                                    "confirm_os_window_close 0\nshell_integration disabled\n" + mouse_maps + "\n")
            launch = ["dbus-run-session", "--", args.kitty, "--config", str(kitty_config), "--title", title] + attach
        elif terminal == "monstar":
            monstar_config = root / "monstar.conf"
            monstar_config.write_text("font-family = monospace\nfont-size = 14\n"
                                      "window-padding-x = 0\nwindow-padding-y = 0\n")
            sway_config = root / "sway.conf"
            terminal_command = ["env", "WAYLAND_DEBUG=client",
                                "DBUS_SESSION_BUS_ADDRESS=unix:path=" + str(root / "no-bus"),
                                args.monstar, "--config", str(monstar_config), "--title", title, "-e"] + attach
            sway_config.write_text("xwayland disable\nseat seat0 fallback true\n"
                                   "default_border none\nfocus_follows_mouse no\n"
                                   "for_window [app_id=\"dev.rockorager.monstar\"] fullscreen enable\n"
                                   "exec " + shlex.join(terminal_command) + "\n")
            env.update(WLR_BACKENDS="x11", WLR_RENDERER="pixman", WLR_X11_OUTPUTS="1",
                       XDG_CURRENT_DESKTOP="sway")
            launch = ["dbus-run-session", "--", "sway", "--unsupported-gpu", "--config", str(sway_config)]
        else:
            launch = ["dbus-run-session", "--", args.ghostty, "--config-default-files=false",
                      "--gtk-single-instance=false", "--title=" + title, "--font-size=14",
                      "--window-padding-x=0", "--window-padding-y=0", "--window-decoration=false",
                      "--shell-integration=none", "--mouse-shift-capture=always", "-e"] + attach
        with (root / "terminal.log").open("w") as log, process(launch, env, log):
            window_title = "" if terminal == "monstar" else "^" + title + "$"
            window = wait_for(lambda: run("xdotool", "search", "--onlyvisible", "--name", window_title,
                                          env=env, check=False).splitlines(), "terminal window")[-1]
            wait_for(lambda: tmux("list-clients", "-F", "#{client_name}"), "attached client")
            run("xdotool", "windowsize", window, "800", "500", env=env)
            run("xdotool", "windowfocus", window, env=env)
            time.sleep(1)
            height = int(tmux("list-clients", "-F", "#{client_cell_height}"))
            assert height > 0
            assert opened() == [], "Rendering a link launched an opener without a click"
            if terminal == "monstar":
                width = int(tmux("list-clients", "-F", "#{client_cell_width}"))

                def link_pixels(row):
                    return subprocess.run(
                        ["magick", "import", "-window", window, "-crop",
                         f"{10 * width}x{height}+0+{row * height}", "-depth", "8", "rgb:-"],
                        env=env, check=True, capture_output=True, timeout=10).stdout

                run("xdotool", "mousemove", "--window", window, "500", str(height // 2), env=env)
                time.sleep(0.2)
                unhovered = link_pixels(1)
                file_unhovered = link_pixels(0)
                repeated_file_unhovered = link_pixels(6)
                wrapped_top = link_pixels(8)
                wrapped_bottom = link_pixels(9)

                def cursor_shape():
                    shapes = re.findall(r"wp_cursor_shape_device_v1[#@]\d+\.set_shape\(\d+, (\d+)\)",
                                        (root / "terminal.log").read_text())
                    return int(shapes[-1]) if shapes else None

                run("xdotool", "keydown", "ctrl", "shift", env=env)
                try:
                    time.sleep(0.2)
                    assert link_pixels(1) == unhovered, "Ctrl+Shift underlined an unhovered hyperlink"
                    run("xdotool", "mousemove", "--window", window, "45", str(height // 2), env=env)
                    wait_for(lambda: cursor_shape() == 4, "tmux file hover pointer")
                    wait_for(lambda: link_pixels(0) != file_unhovered, "hovered file underline")
                    assert link_pixels(1) == unhovered, "Hover underlined a different hyperlink"
                    assert link_pixels(6) == repeated_file_unhovered, "Hover underlined another occurrence of the same URI"
                    tmux("set", "-g", "mouse-hyperlink-hover", "off")
                    wait_for(lambda: cursor_shape() == 1, "file hover belongs to tmux, not the terminal")
                    tmux("set", "-g", "mouse-hyperlink-hover", "on")
                    run("xdotool", "mousemove", "--window", window, "500", str(height // 2), env=env)
                    wait_for(lambda: cursor_shape() == 1, "pointer reset away from file")
                    run("xdotool", "mousemove", "--window", window, "45", str(height // 2), env=env)
                    wait_for(lambda: cursor_shape() == 4, "tmux file hover restored")
                    run("xdotool", "mousemove", "--window", window, "500", str(height // 2), env=env)
                    wait_for(lambda: cursor_shape() == 1, "pointer reset after file")
                    wait_for(lambda: link_pixels(0) == file_unhovered, "file underline cleared")
                    run("xdotool", "mousemove", "--window", window, "45", str(height + height // 2), env=env)
                    wait_for(lambda: link_pixels(1) != unhovered, "hovered web underline")
                    assert link_pixels(0) == file_unhovered, "Web hover underlined a file link"
                    assert link_pixels(8) == wrapped_top, "Web hover underlined another occurrence of the same URI"
                    run("xdotool", "mousemove", "--window", window, "45", str(8 * height + height // 2), env=env)
                    wait_for(lambda: link_pixels(8) != wrapped_top and link_pixels(9) != wrapped_bottom,
                             "both rows of the hovered wrapped hyperlink are underlined")
                    wait_for(lambda: link_pixels(1) == unhovered, "previous web underline cleared")
                    run("xdotool", "mousemove", "--window", window, "500", str(height // 2), env=env)
                    wait_for(lambda: link_pixels(8) == wrapped_top and link_pixels(9) == wrapped_bottom,
                             "wrapped underline cleared")
                    tmux("set", "-g", "mouse", "off")
                    run("xdotool", "mousemove", "--window", window, "45", str(height + height // 2), env=env)
                    wait_for(lambda: link_pixels(1) != unhovered, "hover underline without mouse reporting")
                    assert link_pixels(0) == file_unhovered, "Uncaptured hover underlined an unrelated file"
                    assert link_pixels(8) == wrapped_top, "Uncaptured hover underlined a repeated URI"
                    run("xdotool", "mousemove", "--window", window, "500", str(height // 2), env=env)
                    wait_for(lambda: link_pixels(1) == unhovered, "uncaptured underline cleared")
                    tmux("set", "-g", "mouse", "on")
                finally:
                    run("xdotool", "keyup", "shift", "ctrl", env=env)
                assert opened() == [], "Hover launched an opener without a click"
            for row, url in enumerate(WEB_URLS, start=1):
                click(env, window, 45, row * height + height // 2)
                expected = ["local\t1\t" + item for item in WEB_URLS[:row]]
                wait_for(lambda: opened() == expected, f"local opener for {url}; got {opened()!r}")
                assert editor_state(editor) == ["", 1, 1]
            for row in (5, 7):
                click(env, window, 45, row * height + height // 2)
                time.sleep(0.3)
                assert opened() == expected, "Non-web link/text reached the local opener"
                assert editor_state(editor) == ["", 1, 1]
            for modified in (True, False):
                for row in (0, 6):
                    run(args.nvim, "--server", editor, "--remote-expr", "execute('enew')", env=env)
                    tmux("select-window", "-t", "probe:0")
                    time.sleep(0.2)
                    click(env, window, 45, row * height + height // 2, modified=modified)
                    wait_for(lambda: editor_state(editor) == [str(target), 49, 2], "correct file and location")
                    wait_for(lambda: tmux("display", "-p", "-t", "probe", "#{window_name}") == "editor", "existing editor selected")
                    assert len(tmux("list-windows", "-t", "probe", "-F", "#{window_id}").splitlines()) == 2
                    assert editor_state(decoy) == ["", 1, 1]
                    assert opened() == expected, "File link reached the local opener"
        print(f"PASS {terminal}/{transport}: web local, files in correct Neovim, schemes filtered", flush=True)
    except Exception:
        print(tmux("capture-pane", "-p", "-t", "probe:0", check=False), flush=True)
        print(f"Browser invocations: {opened()!r}", flush=True)
        raise
    finally:
        tmux("kill-server", check=False)


def main(args, root):
    base_env = {key: value for key, value in os.environ.items()
                if key not in {"TMUX", "TMUX_PANE", "WAYLAND_DISPLAY", "DBUS_SESSION_BUS_ADDRESS"}}
    base_env.update(LIBGL_ALWAYS_SOFTWARE="1", GDK_BACKEND="x11")
    ssh_root = root / "ssh"
    ssh_root.mkdir(mode=0o700)
    for name in ("host", "client"):
        run("ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(ssh_root / name))
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        port = listener.getsockname()[1]
    ssh_config = ssh_root / "sshd.conf"
    ssh_config.write_text(f"""ListenAddress 127.0.0.1
Port {port}
HostKey {ssh_root}/host
PidFile {ssh_root}/pid
AuthorizedKeysFile {ssh_root}/client.pub
StrictModes no
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
AllowUsers {pwd.getpwuid(os.getuid()).pw_name}
LogLevel ERROR
""")
    ssh = ["ssh", "-F", "/dev/null", "-p", str(port), "-i", str(ssh_root / "client"),
           "-o", "IdentitiesOnly=yes", "-o", "BatchMode=yes", "-o", "StrictHostKeyChecking=no",
           "-o", "UserKnownHostsFile=" + str(ssh_root / "known_hosts"), "-tt", "127.0.0.1"]
    read_fd, write_fd = os.pipe()
    with (root / "services.log").open("w") as log, \
            process([shutil.which("sshd"), "-D", "-e", "-f", str(ssh_config)], base_env, log), \
            process(["Xvfb", "-displayfd", str(write_fd), "-screen", "0", "1024x768x24",
                     "-nolisten", "tcp", "-ac"], base_env, log, pass_fds=(write_fd,)):
        os.close(write_fd)
        with os.fdopen(read_fd) as stream:
            base_env["DISPLAY"] = ":" + stream.readline().strip()
        run(*ssh, "true", env=base_env)
        for terminal in args.terminals:
            for transport in ("local", "ssh"):
                check_case(args, root / f"{terminal}-{transport}", terminal, transport, base_env, ssh)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Linux GUI regression: HTTP local, files tmux-side, over direct SSH")
    for tool in ("ghostty", "kitty", "monstar", "tmux", "nvim", "opener"):
        parser.add_argument("--" + tool, default=shutil.which("tmux-open-nvim-link" if tool == "opener" else tool))
    parser.add_argument("--terminals", nargs="+", choices=("ghostty", "kitty", "monstar"), default=["ghostty", "kitty"])
    parser.add_argument("--keep", action="store_true", help="Keep isolated logs and fixtures for debugging")
    arguments = parser.parse_args()
    required_tools = ["Xvfb", "xdotool", "dbus-run-session", "sshd", "ssh", "ssh-keygen"]
    if "monstar" in arguments.terminals:
        required_tools.extend(["sway", "magick"])
    for tool in required_tools:
        if not shutil.which(tool):
            parser.error(f"Missing executable: {tool}")
    for tool in [*arguments.terminals, "tmux", "nvim", "opener"]:
        if not getattr(arguments, tool):
            parser.error(f"Missing executable: {tool}")
    root = Path(tempfile.mkdtemp(prefix="terminal-routing-"))
    print(f"Isolated fixtures: {root}", flush=True)
    try:
        main(arguments, root)
    finally:
        if not arguments.keep:
            shutil.rmtree(root)
