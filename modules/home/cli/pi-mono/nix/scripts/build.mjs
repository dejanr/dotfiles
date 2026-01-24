import { readFile } from "node:fs/promises";
import { createRequire } from "node:module";
import { resolve } from "node:path";

const cwd = process.cwd();
const workspaceRoot = resolve(cwd, "..");
const packageJsonPath = resolve(cwd, "package.json");
const require = createRequire(resolve(workspaceRoot, "package.json"));
const { build } = require("esbuild");

let peerDependencies = [];
try {
  const packageJson = JSON.parse(await readFile(packageJsonPath, "utf8"));
  peerDependencies = Object.keys(packageJson.peerDependencies ?? {});
} catch (error) {
  console.error(error);
  process.exit(1);
}

const external = new Set(["@mariozechner/*", ...peerDependencies]);

try {
  await build({
    entryPoints: [resolve(cwd, "index.ts")],
    outfile: resolve(cwd, "dist/index.js"),
    bundle: true,
    platform: "node",
    format: "esm",
    target: "node18",
    external: Array.from(external),
  });
} catch (error) {
  console.error(error);
  process.exit(1);
}
