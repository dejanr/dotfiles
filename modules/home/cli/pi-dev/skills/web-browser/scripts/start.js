#!/usr/bin/env node

import { execSync, spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const useProfile = process.argv[2] === "--profile";

if (process.argv[2] && process.argv[2] !== "--profile") {
  console.log("Usage: start.ts [--profile]");
  console.log("\nOptions:");
  console.log(
    "  --profile  Copy your default Chrome profile (cookies, logins)",
  );
  console.log("\nExamples:");
  console.log("  start.ts            # Start with fresh profile");
  console.log("  start.ts --profile  # Start with your Chrome profile");
  process.exit(1);
}

const homeDir = process.env["HOME"] ?? "";
const platform = process.platform;

const commandExists = (command) => {
  try {
    execSync(`command -v ${command}`, { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
};

const resolveChromeBinary = () => {
  if (platform === "darwin") {
    const macPath = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";
    return existsSync(macPath) ? macPath : null;
  }

  const candidates = [
    "google-chrome-stable",
    "google-chrome",
    "chromium",
    "chromium-browser",
  ];

  for (const candidate of candidates) {
    if (commandExists(candidate)) {
      return candidate;
    }
  }

  return null;
};

const resolveProfileSource = () => {
  if (platform === "darwin") {
    const macProfile = `${homeDir}/Library/Application Support/Google/Chrome`;
    return existsSync(macProfile) ? macProfile : null;
  }

  const candidates = [
    `${homeDir}/.config/google-chrome`,
    `${homeDir}/.config/google-chrome-stable`,
    `${homeDir}/.config/chromium`,
  ];

  return candidates.find((candidate) => existsSync(candidate)) ?? null;
};

const chromePath = resolveChromeBinary();
if (!chromePath) {
  console.error("✗ Chrome binary not found. Expected google-chrome-stable on NixOS.");
  process.exit(1);
}

const killCandidates = platform === "darwin"
  ? ["Google Chrome"]
  : ["google-chrome-stable", "google-chrome", "chromium", "chromium-browser"];

for (const name of killCandidates) {
  try {
    execSync(`killall '${name}'`, { stdio: "ignore" });
  } catch {}
}

await new Promise((r) => setTimeout(r, 1000));

execSync("mkdir -p ~/.cache/scraping", { stdio: "ignore" });

if (useProfile) {
  const profileSource = resolveProfileSource();
  if (profileSource) {
    execSync(
      `rsync -a --delete "${profileSource}/" ~/.cache/scraping/`,
      { stdio: "pipe" },
    );
  } else {
    console.warn("⚠ No Chrome profile found; starting with a fresh profile.");
  }
}

spawn(
  chromePath,
  [
    "--remote-debugging-port=9222",
    `--user-data-dir=${homeDir}/.cache/scraping`,
    "--profile-directory=Default",
    "--disable-search-engine-choice-screen",
    "--no-first-run",
    "--disable-features=ProfilePicker",
  ],
  { detached: true, stdio: "ignore" },
).unref();

let connected = false;
for (let i = 0; i < 30; i++) {
  try {
    const response = await fetch("http://localhost:9222/json/version");
    if (response.ok) {
      connected = true;
      break;
    }
  } catch {
    await new Promise((r) => setTimeout(r, 500));
  }
}

if (!connected) {
  console.error("✗ Failed to connect to Chrome");
  process.exit(1);
}

const scriptDir = dirname(fileURLToPath(import.meta.url));
const watcherPath = join(scriptDir, "watch.js");
spawn(process.execPath, [watcherPath], { detached: true, stdio: "ignore" }).unref();

console.log(
  `✓ Chrome started on :9222${useProfile ? " with your profile" : ""}`,
);
