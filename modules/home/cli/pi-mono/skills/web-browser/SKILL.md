---
name: web-browser
description: "Allows to interact with web pages by performing actions such as clicking buttons, filling out forms, and navigating links. Use qutebrowser unless told to use chrome. It works by remote controlling Google Chrome or Chromium browsers using the Chrome DevTools Protocol (CDP). When Claude needs to browse the web, it can use this skill to do so."
license: Stolen from Armin who stoled it from Mario
---

# Web Browser Skill

Minimal CDP tools for collaborative site exploration.

## Start Chrome

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/start.js              # Fresh profile
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/start.js --profile    # Copy your profile (cookies, logins)
```

Start Chrome on `:9222` with remote debugging. On NixOS this resolves `google-chrome-stable` (with fallbacks).

## Start Qutebrowser (NixOS)

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/start-qute.js
```

Starts qutebrowser with the `AGENTS` profile and enables CDP on `:9222` via `QTWEBENGINE_REMOTE_DEBUGGING`.

## Navigate

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/nav.js https://example.com
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/nav.js https://example.com --new
```

Navigate current tab or open new tab.

**Qutebrowser note:** `--new` (Target.createTarget) is not supported. Use qutebrowser CLI for background tabs:

```bash
qutebrowser -B "$HOME/.browser/AGENTS" -C "$HOME/.config/qutebrowser/config.py" --target tab-bg-silent "https://example.com"
```

## Evaluate JavaScript

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/eval.js 'document.title'
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/eval.js 'document.querySelectorAll("a").length'
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/eval.js 'JSON.stringify(Array.from(document.querySelectorAll("a")).map(a => ({ text: a.textContent.trim(), href: a.href })).filter(link => !link.href.startsWith("https://")))'
```

Execute JavaScript in active tab (async context). Be careful with string escaping, best to use single quotes.

## Screenshot

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/screenshot.js
```

Screenshot current viewport, returns temp file path

## Pick Elements

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/pick.js "Click the submit button"
```

Interactive element picker. Click to select, Cmd/Ctrl+Click for multi-select, Enter to finish.

## Dismiss Cookie Dialogs

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/dismiss-cookies.js          # Accept cookies
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/dismiss-cookies.js --reject # Reject cookies (where possible)
```

Automatically dismisses EU cookie consent dialogs.

Run after navigating to a page:

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/nav.js https://example.com && /home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/dismiss-cookies.js
```

## Background Logging (Console + Errors + Network)

Automatically started by `start.js` and writes JSONL logs to:

```
~/.cache/agent-web/logs/YYYY-MM-DD/<targetId>.jsonl
```

Manually start:

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/watch.js
```

Tail latest log:

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/logs-tail.js           # dump current log and exit
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/logs-tail.js --follow  # keep following
```

Summarize network responses:

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-mono/skills/web-browser/scripts/net-summary.js
```
