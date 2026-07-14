#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from itertools import count

import websocket

DEFAULT_WARNING_PATTERN = r"idle|inactive|inactivity|are you still|still playing|still there|session.*(end|timeout)|60 seconds|one minute"
DEFAULT_ENDED_PATTERN = r"session ended due to inactivity|game session ended due to inactivity|launch the game again"


def parse_args():
    parser = argparse.ArgumentParser(description="Watch GeForce NOW for idle warnings and send a keepalive pulse.")
    parser.add_argument("--cdp-url", default="http://127.0.0.1:9222")
    parser.add_argument("--interval", type=float, default=5.0)
    parser.add_argument("--cooldown", type=float, default=90.0)
    parser.add_argument("--pulse-interval", type=float, default=60.0)
    parser.add_argument("--target-pattern", default=r"geforce now|play\.geforcenow\.com")
    parser.add_argument("--warning-pattern", default=DEFAULT_WARNING_PATTERN)
    parser.add_argument("--ended-pattern", default=DEFAULT_ENDED_PATTERN)
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    return parser.parse_args()


def load_json(url):
    with urllib.request.urlopen(url, timeout=2) as response:
        return json.loads(response.read().decode("utf-8"))


def find_targets(cdp_url, target_pattern):
    targets = load_json(cdp_url.rstrip("/") + "/json")
    target_re = re.compile(target_pattern, re.IGNORECASE)
    return [
        target
        for target in targets
        if target.get("type") == "page"
        and target.get("webSocketDebuggerUrl")
        and target_re.search(" ".join([target.get("title", ""), target.get("url", "")]))
    ]


def cdp_evaluate(websocket_url, expression):
    ws = websocket.create_connection(websocket_url, timeout=3, suppress_origin=True)
    ids = count(1)
    try:
        message_id = next(ids)
        ws.send(json.dumps({
            "id": message_id,
            "method": "Runtime.evaluate",
            "params": {
                "expression": expression,
                "returnByValue": True,
                "awaitPromise": True,
            },
        }))
        while True:
            message = json.loads(ws.recv())
            if message.get("id") == message_id:
                if "error" in message:
                    raise RuntimeError(message["error"])
                result = message.get("result", {}).get("result", {})
                return result.get("value")
    finally:
        ws.close()


def page_text(target):
    expression = """
(() => {
  const visibleText = document.body ? document.body.innerText : "";
  const buttons = Array.from(document.querySelectorAll('button,[role="button"],a'))
    .map((element) => (element.innerText || element.textContent || '').trim())
    .filter(Boolean);
  return JSON.stringify({ title: document.title, url: location.href, visibleText, buttons });
})()
"""
    value = cdp_evaluate(target["webSocketDebuggerUrl"], expression)
    if not value:
        return {"visibleText": "", "buttons": []}
    return json.loads(value)


def click_continue_button(target):
    expression = r"""
(() => {
  const labelPattern = /continue|resume|stay|yes|ok/i;
  const elements = Array.from(document.querySelectorAll('button,[role="button"],a'));
  const element = elements.find((candidate) => labelPattern.test((candidate.innerText || candidate.textContent || '').trim()));
  if (!element) return false;
  element.click();
  return true;
})()
"""
    return bool(cdp_evaluate(target["webSocketDebuggerUrl"], expression))


def focus_geforce_window():
    try:
        output = subprocess.check_output(["niri", "msg", "-j", "windows"], text=True, timeout=2)
    except (FileNotFoundError, subprocess.SubprocessError):
        return False

    windows = json.loads(output)
    for window in windows:
        title = window.get("title") or ""
        app_id = window.get("app_id") or ""
        if "geforce now" in title.lower() and "chrome" in app_id.lower():
            subprocess.run(["niri", "msg", "action", "focus-window", "--id", str(window["id"])], check=False)
            return True
    return False


def send_activity_pulse(dry_run):
    if dry_run:
        print("dry-run: would focus GeForce NOW and send mouse pulse")
        return

    focus_geforce_window()
    subprocess.run(["ydotool", "mousemove", "--", "1", "0"], check=True)
    time.sleep(0.15)
    subprocess.run(["ydotool", "mousemove", "--", "-1", "0"], check=True)


def notify(message):
    subprocess.run(["notify-send", "GeForce NOW keepalive", message], check=False)


def is_stream_target(target):
    url = target.get("url", "").lower()
    return "/streamer" in url or "applaunchmode" in url


def warning_snippet(text, warning_re):
    for line in text.splitlines():
        if warning_re.search(line):
            return line.strip()[:200]
    return "idle warning detected"


def main():
    args = parse_args()
    warning_re = re.compile(args.warning_pattern, re.IGNORECASE)
    ended_re = re.compile(args.ended_pattern, re.IGNORECASE)
    last_pulse_at = 0.0
    last_ended_notification_at = 0.0

    while True:
        try:
            targets = find_targets(args.cdp_url, args.target_pattern)
            if not targets:
                print("No GeForce NOW CDP target found", file=sys.stderr)
            for target in targets:
                content = page_text(target)
                text = "\n".join([content.get("visibleText", ""), "\n".join(content.get("buttons", []))])
                now = time.monotonic()

                if ended_re.search(text):
                    if now - last_ended_notification_at >= args.cooldown:
                        print(f"session already ended in {target.get('title', 'GeForce NOW')}: inactivity")
                        notify("Session already ended due to inactivity; launch the game again.")
                        last_ended_notification_at = now
                    continue

                if warning_re.search(text):
                    if now - last_pulse_at < args.cooldown:
                        continue

                    snippet = warning_snippet(text, warning_re)
                    print(f"warning in {target.get('title', 'GeForce NOW')}: {snippet}")
                    clicked = False if args.dry_run else click_continue_button(target)
                    send_activity_pulse(args.dry_run)
                    notify("Idle warning detected; clicked continue." if clicked else "Idle warning detected; sent activity pulse.")
                    last_pulse_at = now
                    continue

                if args.pulse_interval > 0 and is_stream_target(target) and now - last_pulse_at >= args.pulse_interval:
                    print(f"sent periodic activity pulse to {target.get('title', 'GeForce NOW')}")
                    send_activity_pulse(args.dry_run)
                    last_pulse_at = now
        except (urllib.error.URLError, TimeoutError, ConnectionError) as error:
            print(f"Could not connect to Chrome CDP at {args.cdp_url}: {error}", file=sys.stderr)
        except Exception as error:
            print(f"GeForce NOW keepalive error: {error}", file=sys.stderr)

        if args.once:
            return
        time.sleep(args.interval)


if __name__ == "__main__":
    main()
