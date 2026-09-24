#!/usr/bin/env node

import { execSync, spawn } from "node:child_process";

const commandExists = (command) => {
  try {
    execSync(`command -v ${command}`, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
};

const isQuteRunning = () => {
  try {
    execSync("pgrep -x qutebrowser", { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
};

const fetchEndpoint = async () => {
  try {
    const response = await fetch("http://localhost:9222/json/version");
    if (!response.ok) {
      return null;
    }
    return await response.json();
  } catch {
    return null;
  }
};

if (!commandExists("qutebrowser")) {
  console.error("✗ qutebrowser not found on PATH");
  process.exit(1);
}

const homeDir = process.env["HOME"] ?? "";
const profileDir = `${homeDir}/.browser/AGENTS`;
const configPath = `${homeDir}/.config/qutebrowser/config.py`;
const homePage = `${profileDir}/config/qute-home.html`;

const endpoint = await fetchEndpoint();
if (endpoint?.Browser?.toLowerCase().includes("qutebrowser")) {
  console.log("✓ qutebrowser already running on :9222");
  process.exit(0);
}

if (endpoint) {
  console.error(`✗ Port 9222 is already in use by: ${endpoint.Browser ?? "unknown"}`);
  process.exit(1);
}

if (isQuteRunning()) {
  try {
    execSync("pkill -x qutebrowser", { stdio: "ignore" });
  } catch {}
  await new Promise((r) => setTimeout(r, 500));
}

try {
  execSync(`mkdir -p "${profileDir}"`, { stdio: "ignore" });
} catch {}

spawn(
  "qutebrowser",
  [
    "-B",
    profileDir,
    "-C",
    configPath,
    "-s",
    "window.title_format",
    " {perc}[AGENTS]{title_sep}{current_title}",
    "-s",
    "url.start_pages",
    homePage,
    "-s",
    "url.default_page",
    homePage,
  ],
  {
    detached: true,
    stdio: "ignore",
    env: {
      ...process.env,
      QTWEBENGINE_REMOTE_DEBUGGING: "9222",
    },
  },
).unref();

let connected = false;
for (let i = 0; i < 30; i++) {
  const status = await fetchEndpoint();
  if (status?.Browser?.toLowerCase().includes("qutebrowser")) {
    connected = true;
    break;
  }
  await new Promise((r) => setTimeout(r, 500));
}

if (!connected) {
  console.error("✗ Failed to connect to qutebrowser CDP");
  process.exit(1);
}

console.log("✓ qutebrowser started on :9222");
