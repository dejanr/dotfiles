#!/usr/bin/env python3
import argparse
from contextlib import contextmanager
import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import shlex
import struct
import subprocess
import sys
import tempfile
import termios
import time

POINTER = b"\033]22;pointer\033\\"
DEFAULT = b"\033]22;default\033\\"
TEXT = b"\033]22;text\033\\"
ALL_MOTION = b"\033[?1003h"
URL = "file:///tmp/hover%20test.txt#L49C2"


def drain(fd, duration=0.2):
    output = bytearray()
    deadline = time.monotonic() + duration
    while (remaining := deadline - time.monotonic()) > 0:
        if not select.select([fd], [], [], remaining)[0]:
            break
        try:
            chunk = os.read(fd, 65536)
        except OSError as error:
            if error.errno == errno.EIO:
                break
            raise
        if not chunk:
            break
        output.extend(chunk)
    return bytes(output)


def expect(fd, sequence):
    output = bytearray()
    deadline = time.monotonic() + 3
    while time.monotonic() < deadline:
        output.extend(drain(fd, 0.05))
        if sequence in output:
            return bytes(output)
    raise AssertionError(f"Missing {sequence!r} in {bytes(output)!r}")


def move(fd, x=2, y=1, modifiers=20):
    os.write(fd, f"\033[<{35 + modifiers};{x};{y}M".encode())


@contextmanager
def client(command, env, readonly=False):
    pid, fd = pty.fork()
    if pid == 0:
        fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 24, 80, 0, 0))
        args = command + ["attach", "-t", "hover"] + (["-r"] if readonly else [])
        os.execvpe(args[0], args, env)
    try:
        yield fd
    finally:
        os.close(fd)
        os.waitpid(pid, 0)


def run_tests(binary, root):
    env = {key: value for key, value in os.environ.items() if key not in {"TMUX", "TMUX_PANE"}}
    env.update(TERM="xterm-256color", HOME=str(root), XDG_CONFIG_HOME=str(root))
    config = root / "tmux.conf"
    config.write_text("set -g mouse on\nset -g status off\nset -g focus-events on\n"
                      "bind -T root C-S-MouseUp1Pane set -gF @clicked '#{mouse_hyperlink}'\n"
                      "bind -n F12 display-popup -E 'sleep 60'\n")
    received = root / "received"
    received.touch()
    emitter = root / "emit.py"
    emitter.write_text(f"""import os, tty
from pathlib import Path
tty.setraw(0)
os.write(1, b'\\033[2J\\033[H\\033]8;;{URL}\\033\\\\CLICK_LINK\\033]8;;\\033\\\\ plain text\\r\\n')
while True:
    data = os.read(0, 4096)
    if data == b'\\x01':
        os.write(1, b'\\033[?1003h\\033[?1006h')
    elif data == b'\\x02':
        os.write(1, b'\\033[?1003l\\033[?1006l')
    else:
        with Path({str(received)!r}).open('ab') as stream:
            stream.write(data)
""")
    command = [binary, "-S", str(root / "socket")]

    def tmux(*args, check=True):
        return subprocess.run(command + list(args), env=env, check=check,
                              capture_output=True, text=True, timeout=5).stdout.strip()

    def hover(fd):
        drain(fd)
        move(fd)
        expect(fd, POINTER)

    def no_pointer(fd, **kwargs):
        drain(fd)
        move(fd, **kwargs)
        assert POINTER not in drain(fd), "Unexpected pointer"

    try:
        tmux("-f", str(config), "new-session", "-d", "-s", "hover",
             shlex.join([sys.executable, str(emitter)]))
        assert tmux("show", "-gv", "mouse-hyperlink-hover") == "off"
        with client(command, env) as first, client(command, env) as second:
            assert ALL_MOTION not in expect(first, b"CLICK_LINK")
            assert ALL_MOTION not in expect(second, b"CLICK_LINK")
            no_pointer(first)
            tmux("set", "-g", "mouse-hyperlink-hover", "on")
            expect(first, ALL_MOTION)
            expect(second, ALL_MOTION)
            hover(first)
            hover(first)
            assert POINTER not in drain(second), "Pointer leaked between clients"
            assert received.read_bytes() == b"", "Hover leaked to a non-mouse application"
            print("PASS opt-in, all-motion, repeated hover, client isolation, no input leak")

            for position in ({"x": 20}, {"y": 2}, {"modifiers": 0},
                             {"modifiers": 4}, {"modifiers": 16}, {"modifiers": 28}):
                hover(first)
                move(first, **position)
                output = expect(first, DEFAULT)
                assert POINTER not in output
            print("PASS link boundaries and exact modifiers")

            hover(first)
            os.write(first, b"\033[<20;2;1M\033[<20;2;1m")
            expect(first, DEFAULT)
            assert tmux("show", "-gv", "@clicked") == URL
            hover(first)
            os.write(first, b"x")
            expect(first, DEFAULT)
            hover(first)
            os.write(first, b"\033[O")
            expect(first, DEFAULT)
            os.write(first, b"\033[I")
            print("PASS click hyperlink, keyboard and focus reset")

            for option in ("mouse-hyperlink-hover", "mouse"):
                hover(first)
                tmux("set", "-g", option, "off")
                output = expect(first, DEFAULT)
                assert b"\033[?1003l" in output
                no_pointer(first)
                tmux("set", "-g", option, "on")
                expect(first, ALL_MOTION)
            print("PASS runtime option reset")

            hover(first)
            tmux("copy-mode", "-t", "hover:0")
            expect(first, DEFAULT)
            no_pointer(first)
            tmux("send-keys", "-t", "hover:0", "-X", "cancel")
            hover(first)
            tmux("new-window", "-t", "hover", "-n", "other", "sleep 60")
            expect(first, DEFAULT)
            no_pointer(first)
            tmux("select-window", "-t", "hover:0")
            hover(first)
            tmux("set", "-g", "status", "on")
            drain(first)
            move(first, y=24)
            expect(first, DEFAULT)
            print("PASS copy mode, window switch and status reset")

            for keys in (b"\x02:", b"\033[24~"):
                hover(first)
                os.write(first, keys)
                expect(first, DEFAULT)
                no_pointer(first)
                os.write(first, b"\x03")
                drain(first, 0.6)
            print("PASS command prompt and popup isolation")

            tmux("new-session", "-d", "-s", "other", "sleep 60")
            clients = tmux("list-clients", "-F", "#{client_tty}").splitlines()
            hover(first)
            for target in clients:
                tmux("switch-client", "-c", target, "-t", "other")
            expect(first, DEFAULT)
            no_pointer(first)
            for target in clients:
                tmux("switch-client", "-c", target, "-t", "hover")
            print("PASS session switch reset")

            received.write_bytes(b"")
            tmux("send-keys", "-t", "hover:0", "C-a")
            deadline = time.monotonic() + 3
            while tmux("display", "-p", "-t", "hover:0", "#{mouse_any_flag}") != "1":
                assert time.monotonic() < deadline
                time.sleep(0.05)
            hover(first)
            assert b"\033[<55;2;1M" in received.read_bytes()
            tmux("set", "-g", "mouse-hyperlink-hover", "off")
            output = expect(first, DEFAULT)
            assert b"\033[?1003l" not in output, "Disabled application's all-motion mode"
            print("PASS application motion forwarding and mode preservation")
            tmux("set", "-g", "mouse-hyperlink-hover", "on")
            hover(first)

            with client(command, env, readonly=True) as readonly:
                expect(readonly, b"CLICK_LINK")
                no_pointer(readonly)
            hover(second)
            tmux("detach-client", "-s", "hover")
            expect(first, TEXT)
            expect(second, TEXT)
            print("PASS read-only client and detach cleanup")
    finally:
        tmux("kill-server", check=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Exercise patched tmux hover using isolated PTY clients")
    parser.add_argument("tmux", help="Path to the patched tmux binary")
    args = parser.parse_args()
    with tempfile.TemporaryDirectory(prefix="tmux-hover-") as directory:
        run_tests(args.tmux, Path(directory))
