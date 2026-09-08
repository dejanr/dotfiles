import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, realpathSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';
import { findProjectRoot, inspectInstallation, parseSmokeArguments, validateVersions } from './launcher.mjs';

const expected = {
  nodeVersion: process.versions.node,
  playwrightVersion: '1.56.1',
  browsers: {
    chromium: { revision: '1194' },
    firefox: { revision: '1495' },
    webkit: { revision: '2215' },
  },
};
const metadata = Object.entries(expected.browsers).map(([name, browser]) => ({ name, ...browser }));

function write(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, typeof content === 'string' ? content : JSON.stringify(content));
}

function project(t) {
  const root = realpathSync(mkdtempSync(join(tmpdir(), 'ctf playwright ')));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  write(join(root, 'rush.json'), { rushVersion: '5.166.0', pnpmVersion: '10.27.0' });
  write(join(root, 'framework/e2e-tests/playwright/package.json'), {
    devDependencies: { '@playwright/test': '1.56.1' },
  });
  return root;
}

function installFixture(root) {
  for (const name of ['@playwright/test', 'playwright', 'playwright-core']) {
    write(join(root, 'node_modules', name, 'package.json'), { name, version: '1.56.1', main: 'index.cjs' });
  }
  write(
    join(root, 'node_modules/@playwright/test/index.cjs'),
    'module.exports = Object.fromEntries(["chromium", "firefox", "webkit"].map(name => [name, { executablePath: () => process.execPath }]));',
  );
  write(join(root, 'node_modules/playwright-core/browsers.json'), { browsers: metadata });
  write(
    join(root, 'node_modules/playwright-core/lib/server/utils/hostPlatform.js'),
    'exports.hostPlatform = "mac15-arm64";',
  );
}

test('smoke checks default to all engines headlessly and allow a selected headed engine', () => {
  assert.deepEqual(parseSmokeArguments([]), { engines: ['chromium', 'firefox', 'webkit'], headed: false });
  assert.deepEqual(parseSmokeArguments(['firefox', '--headed']), { engines: ['firefox'], headed: true });
  assert.deepEqual(parseSmokeArguments(['--headed', 'chromium']), { engines: ['chromium'], headed: true });
});

test('smoke checks reject unknown or duplicate options', () => {
  for (const args of [['safari'], ['firefox', 'webkit'], ['--headed', '--headed'], ['--workers', '1']]) {
    assert.throws(() => parseSmokeArguments(args), /Use --smoke/);
  }
});

test('finds CTF from a nested package with spaces in the checkout path', (t) => {
  const root = project(t);
  assert.equal(findProjectRoot(join(root, 'framework/e2e-tests/playwright')), root);
});

test('rejects directories outside CTF', () => {
  assert.throws(() => findProjectRoot(tmpdir()), /CTF checkout/);
});

test('accepts exact runner and browser revisions', () => {
  validateVersions(expected, '1.56.1', { '@playwright/test': '1.56.1' }, metadata, 'ubuntu24.04-x64');
});

test('rejects changed or ranged project requirements', () => {
  for (const version of ['1.57.0', '^1.56.1']) {
    assert.throws(() => validateVersions(expected, version, {}, metadata), /manifest uses Playwright/);
  }
});

test('rejects stale installed runner and core packages independently', () => {
  for (const name of ['@playwright/test', 'playwright', 'playwright-core']) {
    assert.throws(
      () => validateVersions(expected, '1.56.1', { [name]: '1.55.0' }, metadata),
      /dotfiles browser pin requires 1.56.1/,
    );
  }
});

test('rejects missing or different browser revisions', () => {
  assert.throws(() => validateVersions(expected, '1.56.1', {}, []), /chromium requires revision/);
  assert.throws(
    () => validateVersions(expected, '1.56.1', {}, metadata.map((entry) => ({ ...entry, revision: '1' }))),
    /Nix provides 1194/,
  );
});

test('checks platform-specific WebKit overrides', () => {
  const browsers = metadata.map((entry) =>
    entry.name === 'webkit' ? { ...entry, revisionOverrides: { 'ubuntu20.04-x64': '2092' } } : entry,
  );
  assert.throws(
    () => validateVersions(expected, '1.56.1', {}, browsers, 'ubuntu20.04-x64'),
    /webkit requires revision 2092/,
  );
  validateVersions(expected, '1.56.1', {}, browsers, 'ubuntu24.04-x64');
});

test('accepts current macOS browser revisions on Intel and Apple Silicon', () => {
  for (const platform of ['mac14', 'mac14-arm64', 'mac15', 'mac15-arm64']) {
    validateVersions(expected, '1.56.1', {}, metadata, platform);
  }
});

test('validates the detected platform against older macOS browser overrides', (t) => {
  const root = project(t);
  installFixture(root);
  write(
    join(root, 'node_modules/playwright-core/lib/server/utils/hostPlatform.js'),
    'exports.hostPlatform = "mac13-arm64";',
  );
  write(join(root, 'node_modules/playwright-core/browsers.json'), {
    browsers: metadata.map((entry) =>
      entry.name === 'webkit' ? { ...entry, revisionOverrides: { 'mac13-arm64': '2140' } } : entry,
    ),
  });
  assert.throws(() => inspectInstallation(root, expected), /webkit requires revision 2140; Nix provides 2215/);
});

test('reports missing dependencies without trying to download them', (t) => {
  assert.throws(() => inspectInstallation(project(t), expected), /run rush install/);
});

test('rejects a different Node runtime', (t) => {
  assert.throws(() => inspectInstallation(project(t), { ...expected, nodeVersion: '0.0.0' }), /Expected Node/);
});

test('resolves installed dependencies relative to the external checkout', (t) => {
  const root = project(t);
  installFixture(root);
  assert.equal(inspectInstallation(root, expected).firefox.executablePath(), process.execPath);
});

test('rejects inherited remote browser connections before inspecting a checkout', () => {
  const result = spawnSync(
    process.execPath,
    [fileURLToPath(new URL('./launcher.mjs', import.meta.url)), 'unused-config', '--check'],
    {
      cwd: tmpdir(),
      env: { ...process.env, PW_TEST_CONNECT_WS_ENDPOINT: 'ws://127.0.0.1:9999' },
      encoding: 'utf8',
    },
  );
  assert.equal(result.status, 1);
  assert.match(result.stderr, /Unset PW_TEST_CONNECT_WS_ENDPOINT/);
});

test('forwards arguments, checkout root and exit status to the CTF bootstrap', (t) => {
  const root = project(t);
  installFixture(root);
  write(join(root, 'runtime.json'), expected);
  write(
    join(root, 'common/scripts/install-run-rush.js'),
    'console.log(JSON.stringify({ args: process.argv.slice(2), cwd: process.cwd() })); process.exitCode = 7;',
  );
  const result = spawnSync(
    process.execPath,
    [fileURLToPath(new URL('./launcher.mjs', import.meta.url)), join(root, 'runtime.json'), '--module', 'article-list', '-g', 'a b'],
    { cwd: join(root, 'framework/e2e-tests/playwright'), encoding: 'utf8' },
  );
  assert.equal(result.status, 7, result.stderr);
  const forwarded = JSON.parse(result.stdout.trim().split('\n').at(-1));
  assert.deepEqual(forwarded, { args: ['e2e', '--module', 'article-list', '-g', 'a b'], cwd: root });
});
