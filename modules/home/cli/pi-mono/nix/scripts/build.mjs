import { readFile } from "node:fs/promises";
import { createRequire } from "node:module";
import { resolve } from "node:path";

const cwd = process.cwd();
const require = createRequire(resolve(cwd, "..", "package.json"));
const { build } = require("esbuild");
const packageJson = JSON.parse(await readFile(resolve(cwd, "package.json"), "utf8"));
const peerDependencies = Object.keys(packageJson.peerDependencies ?? {});

await build({
  entryPoints: [resolve(cwd, "index.ts")],
  outfile: resolve(cwd, "dist/index.js"),
  bundle: true,
  platform: "node",
  format: "esm",
  target: "node18",
  external: ["@mariozechner/*", ...peerDependencies],
});
