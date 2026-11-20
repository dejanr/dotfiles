---
name: web-browser
description: Browse and debug web pages in Google Chrome via CDP. Use for navigation, form interaction, screenshots, and console or network inspection.
license: Stolen from Armin who stoled it from Mario
---

# Web Browser Skill

Minimal CDP tools for collaborative site exploration.

## Start Chrome

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/start.js
```

Starts or reuses an isolated Chrome session with remote debugging on `127.0.0.1:9222`. It leaves regular Chrome windows open. If another browser owns the port, close that debug session before starting.

Use `--profile` only when the user asks to copy their Chrome data. It copies the Personal profile (or the default Chrome profile) into a separate debug profile and needs `rsync`. Saved logins may not carry over. Close the current debug session before switching between modes.

## Navigate

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/nav.js https://example.com
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/nav.js https://example.com --new
```

Navigate current tab or open new tab.

## Evaluate JavaScript

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/eval.js 'document.title'
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/eval.js 'document.querySelectorAll("a").length'
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/eval.js 'JSON.stringify(Array.from(document.querySelectorAll("a")).map(a => ({ text: a.textContent.trim(), href: a.href })).filter(link => !link.href.startsWith("https://")))'
```

Execute JavaScript in active tab (async context). Be careful with string escaping, best to use single quotes.

## Screenshot

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/screenshot.js
```

Screenshot current viewport, returns temp file path

## Pick Elements

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/pick.js "Click the submit button"
```

Interactive element picker. Click to select, Cmd/Ctrl+Click for multi-select, Enter to finish.

## Dismiss Cookie Dialogs

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/dismiss-cookies.js          # Accept cookies
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/dismiss-cookies.js --reject # Reject cookies (where possible)
```

Automatically dismisses EU cookie consent dialogs.

Run after navigating to a page:

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/nav.js https://example.com && /home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/dismiss-cookies.js
```

## Background Logging (Console + Errors + Network)

Automatically started by `start.js` and writes JSONL logs to:

```
~/.cache/agent-web/logs/YYYY-MM-DD/<targetId>.jsonl
```

Manually start:

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/watch.js
```

Tail latest log:

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/logs-tail.js           # dump current log and exit
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/logs-tail.js --follow  # keep following
```

Summarize network responses:

```bash
/home/dejanr/.dotfiles/modules/home/cli/pi-dev/skills/web-browser/scripts/net-summary.js
```
