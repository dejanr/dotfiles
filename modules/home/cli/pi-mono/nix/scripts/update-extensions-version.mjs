import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(scriptDir, "..", "..");

const piMonoSrc = execFileSync(
  "nix",
  [
    "eval",
    "--impure",
    "--raw",
    "--expr",
    "(builtins.getFlake (toString ./.)).inputs.pi-mono.outPath",
  ],
  {
    cwd: repoRoot,
    encoding: "utf8",
  }
).trim();

const piMonoPackageJsonPath = resolve(
  piMonoSrc,
  "packages",
  "coding-agent",
  "package.json"
);
const piMonoPackageJson = JSON.parse(
  readFileSync(piMonoPackageJsonPath, "utf8")
);
const version = piMonoPackageJson.version;

const extensionsPackageJsonPath = resolve(repoRoot, "extensions", "package.json");
const extensionsPackageJson = JSON.parse(
  readFileSync(extensionsPackageJsonPath, "utf8")
);

const dependenciesToUpdate = [
  "@mariozechner/pi-ai",
  "@mariozechner/pi-coding-agent",
  "@mariozechner/pi-tui",
];

for (const dependency of dependenciesToUpdate) {
  if (extensionsPackageJson.devDependencies?.[dependency]) {
    extensionsPackageJson.devDependencies[dependency] = version;
  }
}

writeFileSync(
  extensionsPackageJsonPath,
  `${JSON.stringify(extensionsPackageJson, null, 2)}\n`
);

execFileSync(
  "pnpm",
  ["-C", "extensions", "install", "--lockfile-only", "--ignore-scripts"],
  { cwd: repoRoot, stdio: "inherit" }
);
