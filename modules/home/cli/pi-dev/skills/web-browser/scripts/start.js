#!/usr/bin/env node

import { execFileSync, spawn } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { setTimeout as delay } from "node:timers/promises";
import { fileURLToPath } from "node:url";
import { CDP_VERSION_URL } from "./cdp.js";

const [option, ...extra] = process.argv.slice(2);
if (extra.length || (option !== undefined && option !== "--profile")) {
  console.error("Usage: start.js [--profile]");
  process.exit(1);
}

const useProfile = option === "--profile";
const home = homedir();
const cacheHome = process.env.XDG_CACHE_HOME || join(home, ".cache");
const profileDir = join(cacheHome, "agent-web", useProfile ? "chrome-copy" : "chrome");
const endpointFile = join(profileDir, "cdp-url");

function resolveChromeBinary() {
  if (process.platform === "darwin") {
    const macPath = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
    return existsSync(macPath) ? macPath : null;
  }

  const binaries = ["google-chrome-stable", "google-chrome", "chromium", "chromium-browser"];
  return binaries.find((binary) => {
    try {
      execFileSync("sh", ["-c", 'command -v "$1"', "sh", binary], { stdio: "ignore" });
      return true;
    } catch {
      return false;
    }
  });
}

function resolveProfileSource() {
  if (process.platform === "darwin") {
    const macProfile = join(home, "Library", "Application Support", "Google", "Chrome");
    return existsSync(macProfile) ? macProfile : null;
  }

  const dataHome = process.env.XDG_DATA_HOME || join(home, ".local", "share");
  const configHome = process.env.XDG_CONFIG_HOME || join(home, ".config");
  const candidates = [
    join(dataHome, "chrome-profiles", "Personal"),
    join(configHome, "google-chrome"),
    join(configHome, "google-chrome-stable"),
    join(configHome, "chromium"),
  ];
  return candidates.find((candidate) => existsSync(join(candidate, "Default")));
}

async function fetchVersion() {
  const response = await fetch(CDP_VERSION_URL, {
    signal: AbortSignal.timeout(1000),
  }).catch(() => null);
  if (!response) return null;
  return (await response.json().catch(() => null)) ?? {};
}

async function startChrome() {
  const existing = await fetchVersion();
  if (existing) {
    if (
      existing.webSocketDebuggerUrl &&
      existsSync(endpointFile) &&
      readFileSync(endpointFile, "utf8") === existing.webSocketDebuggerUrl
    ) {
      console.log("✓ Chrome already running on :9222");
      return;
    }
    throw new Error("Port 9222 is already in use by another session. Close it before starting Chrome.");
  }

  const chromePath = resolveChromeBinary();
  if (!chromePath) throw new Error("Google Chrome not found.");

  mkdirSync(profileDir, { recursive: true, mode: 0o700 });
  if (useProfile) {
    const source = resolveProfileSource();
    if (!source) throw new Error("No Chrome profile found to copy.");
    execFileSync("rsync", [
      "-a",
      "--delete",
      "--chmod=go-rwx",
      "--exclude=/Singleton*",
      "--exclude=/DevToolsActivePort",
      source + "/",
      profileDir + "/",
    ]);
  }

  const browser = spawn(
    chromePath,
    [
      "--remote-debugging-address=127.0.0.1",
      "--remote-debugging-port=9222",
      "--user-data-dir=" + profileDir,
      "--profile-directory=Default",
      "--disable-search-engine-choice-screen",
      "--no-first-run",
      "--no-default-browser-check",
      "--disable-features=ProfilePicker",
    ],
    { detached: true, stdio: "ignore" },
  );
  await new Promise((resolve, reject) => {
    browser.once("spawn", resolve);
    browser.once("error", reject);
  });
  browser.unref();

  for (let attempt = 0; attempt < 30; attempt++) {
    const version = await fetchVersion();
    if (
      /^(?:Chrome|Chromium|HeadlessChrome)\//.test(version?.Browser) &&
      version.webSocketDebuggerUrl
    ) {
      writeFileSync(endpointFile, version.webSocketDebuggerUrl, { mode: 0o600 });
      console.log("✓ Chrome started on :9222");
      return;
    }
    await delay(500);
  }
  throw new Error("Failed to connect to Chrome on port 9222.");
}

try {
  await startChrome();
  const watcherPath = fileURLToPath(new URL("./watch.js", import.meta.url));
  spawn(process.execPath, [watcherPath], { detached: true, stdio: "ignore" }).unref();
} catch (error) {
  console.error("✗", error.message);
  process.exitCode = 1;
}
