import { spawn } from 'node:child_process';
import { once } from 'node:events';
import { accessSync, constants, existsSync, readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { dirname, join, resolve } from 'node:path';

const testPackagePath = 'framework/e2e-tests/playwright/package.json';
const engines = ['chromium', 'firefox', 'webkit'];

function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

export function findProjectRoot(directory) {
  let current = resolve(directory);
  while (true) {
    if (existsSync(join(current, 'rush.json')) && existsSync(join(current, testPackagePath))) {
      return current;
    }
    const parent = dirname(current);
    if (parent === current) {
      throw new Error('Run this command from a CTF checkout.');
    }
    current = parent;
  }
}

export function validateVersions(expected, declaredVersion, installedVersions, browserMetadata, platform) {
  for (const [name, version] of Object.entries({ manifest: declaredVersion, ...installedVersions })) {
    if (version !== expected.playwrightVersion) {
      throw new Error(
        `${name} uses Playwright ${version}; the dotfiles browser pin requires ${expected.playwrightVersion}. ` +
          'Align the dotfiles pin with CTF and run rush install if the installed dependencies are stale.',
      );
    }
  }
  for (const [name, browser] of Object.entries(expected.browsers)) {
    const installed = browserMetadata.find((entry) => entry.name === name);
    const revision = installed?.revisionOverrides?.[platform] ?? installed?.revision;
    if (revision !== browser.revision) {
      throw new Error(`${name} requires revision ${revision}; Nix provides ${browser.revision}.`);
    }
  }
}

export function inspectInstallation(root, expected) {
  if (process.versions.node !== expected.nodeVersion) {
    throw new Error(`Expected Node ${expected.nodeVersion}; run through the dotfiles Nix environment.`);
  }

  const manifestPath = join(root, testPackagePath);
  const manifest = readJson(manifestPath);
  const projectRequire = createRequire(manifestPath);
  let testManifestPath;
  try {
    testManifestPath = projectRequire.resolve('@playwright/test/package.json');
  } catch {
    throw new Error('CTF Playwright is not installed. Enter the Nix shell and run rush install.');
  }
  const testRequire = createRequire(testManifestPath);
  const playwrightManifestPath = testRequire.resolve('playwright/package.json');
  const playwrightRequire = createRequire(playwrightManifestPath);
  const coreManifestPath = playwrightRequire.resolve('playwright-core/package.json');
  const { hostPlatform } = playwrightRequire(join(dirname(coreManifestPath), 'lib/server/utils/hostPlatform.js'));

  validateVersions(
    expected,
    manifest.devDependencies['@playwright/test'],
    {
      '@playwright/test': readJson(testManifestPath).version,
      playwright: readJson(playwrightManifestPath).version,
      'playwright-core': readJson(coreManifestPath).version,
    },
    readJson(join(dirname(coreManifestPath), 'browsers.json')).browsers,
    hostPlatform,
  );

  const playwright = projectRequire('@playwright/test');
  for (const engine of engines) {
    accessSync(playwright[engine].executablePath(), constants.X_OK);
  }
  return playwright;
}

export function parseSmokeArguments(args) {
  let engine;
  let headed = false;
  for (const arg of args) {
    if (arg === '--headed' && !headed) {
      headed = true;
    } else if (engines.includes(arg) && !engine) {
      engine = arg;
    } else {
      throw new Error('Use --smoke [chromium|firefox|webkit] [--headed].');
    }
  }
  return { engines: engine ? [engine] : engines, headed };
}

async function smokeTest(playwright, options) {
  for (const engine of options.engines) {
    const browser = await playwright[engine].launch({ headless: !options.headed });
    try {
      const page = await browser.newPage();
      await page.setContent('<title>CTF browser smoke check</title><h1>Ready</h1>');
      if ((await page.title()) !== 'CTF browser smoke check') {
        throw new Error(`${engine} could not render the smoke check.`);
      }
      await page.screenshot();
      console.log(`${engine}: ${browser.version()} — launch, page and screenshot OK`);
    } finally {
      await browser.close();
    }
  }
}

async function main([configPath, ...args]) {
  if (args[0] === '--help' || args[0] === '-h') {
    console.log(`Usage: ctf-playwright [rush e2e options]
       ctf-playwright --check
       ctf-playwright --smoke [chromium|firefox|webkit] [--headed]

Run from a CTF checkout. Checks the installed runner against the pinned Nix browsers.
--check prints versions and executable paths without starting browsers or CTF services.
--smoke launches all three browsers, or the selected browser, without contacting CTF services.
Supports Linux and macOS 14+. On Linux, this Nixpkgs pin supports headless WebKit only.
All other arguments are forwarded to rush e2e. Use rush e2e -h for its options.`);
    return;
  }
  if (args[0] === '--check' && args.length !== 1) {
    throw new Error('Use --check alone.');
  }
  const smokeOptions = args[0] === '--smoke' ? parseSmokeArguments(args.slice(1)) : undefined;
  if (process.env.PW_TEST_CONNECT_WS_ENDPOINT) {
    throw new Error('Unset PW_TEST_CONNECT_WS_ENDPOINT to use the pinned local browsers.');
  }

  const root = findProjectRoot(process.cwd());
  const expected = readJson(configPath);
  const playwright = inspectInstallation(root, expected);
  console.log(`Node ${process.versions.node}; Playwright ${expected.playwrightVersion}; checkout ${root}`);

  if (args[0] === '--check') {
    const rush = readJson(join(root, 'rush.json'));
    console.log(`Rush ${rush.rushVersion}; pnpm ${rush.pnpmVersion} (CTF bootstrap)`);
    console.log(`Platform: ${process.env.PLAYWRIGHT_HOST_PLATFORM_OVERRIDE ?? `${process.platform}-${process.arch}`}`);
    for (const engine of engines) {
      console.log(`${engine}: ${playwright[engine].executablePath()}`);
    }
    return;
  }
  if (smokeOptions) {
    await smokeTest(playwright, smokeOptions);
    return;
  }

  const child = spawn(process.execPath, [join(root, 'common/scripts/install-run-rush.js'), 'e2e', ...args], {
    cwd: root,
    stdio: 'inherit',
  });
  const [code, signal] = await once(child, 'exit');
  if (signal) {
    process.kill(process.pid, signal);
  } else {
    process.exitCode = code;
  }
}

if (import.meta.main) {
  try {
    await main(process.argv.slice(2));
  } catch (error) {
    console.error(`ctf-playwright: ${error.message}`);
    process.exitCode = 1;
  }
}
