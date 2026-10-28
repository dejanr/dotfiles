import argparse
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument("package", type=Path)
package = parser.parse_args().package.resolve()

with tempfile.TemporaryDirectory(prefix="pi-tmux-clipboard-") as directory:
    root = Path(directory)
    env = os.environ.copy()
    for name in (
        "TMUX", "TMUX_PANE", "SSH_CONNECTION", "SSH_CLIENT", "MOSH_CONNECTION",
        "DISPLAY", "PI_CLIPBOARD_OSC52",
    ):
        env.pop(name, None)
    env.update(
        WAYLAND_DISPLAY="test-wayland",
        TEST_CLIPBOARD=str(root / "clipboard"),
        PI_OFFLINE="1",
        PI_CODING_AGENT_DIR=str(root / "agent"),
    )
    binary = root / "bin"
    binary.mkdir()
    writer = binary / "wl-copy"
    shell = shutil.which("sh")
    assert shell is not None
    writer.write_text(
        f'#!{shell}\n'
        'if [ "${1-}" = --primary ]; then\n'
        '  cat > "$TEST_CLIPBOARD.primary"\n'
        'else\n'
        '  cat > "$TEST_CLIPBOARD"\n'
        'fi\n'
    )
    writer.chmod(0o700)
    env["PATH"] = str(binary) + os.pathsep + env["PATH"]
    socket = str(root / "tmux.sock")

    def tmux(*args):
        return subprocess.check_output(
            ["tmux", "-S", socket, *args], env=env, stderr=subprocess.PIPE,
        ).decode().strip()

    def wait_for(path):
        deadline = time.monotonic() + 10
        while not path.exists():
            if time.monotonic() > deadline:
                raise AssertionError(f"timed out waiting for {path.name}")
            time.sleep(0.02)

    marker = "pi-selected-text"
    clipboard = package / "lib/pi-dev/packages/coding-agent/dist/utils/clipboard.js"
    producer = root / "producer.ts"
    producer.write_text(
        f'import {{copyToClipboard, copyToPrimarySelection}} from {json.dumps(clipboard.as_uri())};\n'
        'import {writeFileSync} from "node:fs";\n'
        'export default function (pi) { pi.on("session_start", async () => {\n'
        f'process.env.PATH = {json.dumps(str(binary))} + ":" + process.env.PATH;\n'
        f'await copyToClipboard({json.dumps(marker)});\n'
        f'await copyToPrimarySelection({json.dumps(marker)});\n'
        f'writeFileSync({json.dumps(str(root / "copied"))}, "done");\n'
        '}); }\n'
    )
    receiver = root / "receiver.py"
    receiver.write_text(
        'import os, pathlib, select, sys, time, tty\n'
        'tty.setraw(0)\n'
        'sys.stdout.write("\x1b[?2004h"); sys.stdout.flush()\n'
        f'pathlib.Path({str(root / "ready")!r}).touch()\n'
        'data = b""\n'
        'while select.select([0], [], [], 0.2 if data else 10)[0]:\n'
        '    data += os.read(0, 65536)\n'
        f'pathlib.Path({str(root / "received")!r}).write_bytes(data)\n'
        'time.sleep(60)\n'
    )
    try:
        tmux("-f", "/dev/null", "new-session", "-d", "-s", "repro", "sleep 60")
        tmux("set-option", "-s", "set-clipboard", "on")
        tmux("set-buffer", "stale-tmux-buffer")
        pane = tmux(
            "new-window", "-d", "-P", "-F", "#{pane_id}",
            shlex.join([sys.executable, str(receiver)]),
        )
        wait_for(root / "ready")
        tmux("new-window", "-d", shlex.join([
            str(package / "bin/pi"), "--no-session", "--no-extensions",
            "--extension", str(producer),
        ]))
        wait_for(root / "copied")
        assert (root / "clipboard.primary").read_text() == marker
        time.sleep(0.1)
        tmux("paste-buffer", "-p", "-t", pane)
        wait_for(root / "received")
        received = (root / "received").read_bytes()
        expected = b"\x1b[200~" + marker.encode() + b"\x1b[201~"
        assert received == expected, f"destination got {received!r}, expected the Pi selection"
        print("PASS: Pi selection reaches PRIMARY and another tmux pane as a bracketed paste")
    finally:
        subprocess.run(["tmux", "-S", socket, "kill-server"], env=env, capture_output=True)
