import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { compilerFor, scan } from './scan.mjs';

const ts = await compilerFor(process.cwd(), process.env.E2E_REPORT_TYPESCRIPT);
const directory = () => fs.mkdtempSync(path.join(fs.realpathSync(os.tmpdir()), 'e2e-scan-test-'));

function fixture(t, content, name = 'specs/example.spec.ts') {
  const root = directory();
  t.after(() => fs.rmSync(root, { recursive: true, force: true }));
  fs.mkdirSync(path.dirname(path.join(root, name)), { recursive: true });
  fs.writeFileSync(path.join(root, name), content);
  return root;
}

test('discovers aliased fixtures, literal titles, nested loops, and inherited skips without execution', t => {
  const root = fixture(t, [
    "import { test as base } from '@playwright/test';",
    'const test = base.extend({});',
    "throw new Error('TEST MODULE MUST NOT EXECUTE');",
    "test.describe.skip('Disabled suite', () => {",
    "  for (const brand of brands) {",
    "    test(`case_\${brand}`, async () => {});",
    '  }',
    '});',
    "test('active', async () => { test.skip(true, 'runtime'); });",
  ].join('\n'));
  const result = scan(path.join(root, 'specs'), root, ts);
  assert.equal(result.declarations.length, 2);
  assert.equal(result.declarations[0].status, 'skipped');
  assert.equal(result.declarations[0].source.line, 6);
  assert.equal(result.declarations[0].loops[0].expression, 'brands');
  assert.equal(result.declarations[0].suites[0].titleExpression, "'Disabled suite'");
  assert.equal(result.declarations[1].status, 'declared');
});

test('preserves parallel and serial suite scopes and inherited skips', t => {
  const root = fixture(t, [
    "import { test } from '@playwright/test';",
    "test.describe.parallel('Parallel', () => { test('same', async () => {}); });",
    "test.describe.serial.skip('Serial', () => { test('same', async () => {}); });",
  ].join('\n'));
  const result = scan(root, root, ts);
  assert.equal(result.declarations.length, 2);
  assert.equal(result.declarations[0].suites[0].titleExpression, "'Parallel'");
  assert.equal(result.declarations[1].suites[0].titleExpression, "'Serial'");
  assert.equal(result.declarations[1].status, 'skipped');
});

test('records shared registration candidates and custom test aliases', t => {
  const root = fixture(t, [
    "import { test as scenario } from './fixtures.js';",
    'registerSharedTests(scenario, { brands });',
    "scenario('local', async () => {});",
  ].join('\n'));
  const result = scan(root, root, ts);
  assert.equal(result.registrations.length, 1);
  assert.equal(result.registrations[0].expression, 'registerSharedTests');
  assert.equal(result.declarations.length, 1);
});

test('supports namespaces, forEach context, expected failures, and same-line declarations', t => {
  const root = fixture(t, [
    "import * as pw from '@playwright/test';",
    "brands.forEach(brand => { pw.test.fail('one', async () => {}); pw.test.skip('two', async () => {}); });",
  ].join('\n'));
  const result = scan(root, root, ts);
  assert.equal(result.declarations.length, 2);
  assert.equal(new Set(result.declarations.map(item => item.id)).size, 2);
  assert.equal(result.declarations[0].modifier, '.fail');
  assert.equal(result.declarations[0].loops[0].expression, 'brands');
  assert.equal(result.declarations[1].status, 'skipped');
});

test('does not count comments, steps, hooks, or unrelated object methods as tests', t => {
  const root = fixture(t, [
    "import { test } from '@playwright/test';",
    "// test('comment', async () => {});",
    "test.beforeEach(async () => {});",
    "test.step('step', async () => {});",
    "other.test('unrelated', async () => {});",
    "test('actual', async () => {});",
  ].join('\n'));
  assert.equal(scan(root, root, ts).declarations.length, 1);
});

test('keeps non-Playwright test files in the review ledger but excludes Jest declarations', t => {
  const root = fixture(t, "import {test} from '@jest/globals'; test('unit', () => {});", 'unit.test.ts');
  fs.mkdirSync(path.join(root, 'dist'));
  fs.writeFileSync(path.join(root, 'dist', 'ignored.spec.ts'), "import {test} from '@playwright/test'; test('generated', () => {});");
  const result = scan(root, root, ts);
  assert.equal(result.files.length, 1);
  assert.equal(result.files[0].directDeclarations, 0);
  assert.equal(result.declarations.length, 0);
});

test('rejects a scan folder outside the selected repository', t => {
  const root = fixture(t, '');
  const outside = directory();
  t.after(() => fs.rmSync(outside, { recursive: true, force: true }));
  assert.throws(() => scan(outside, root, ts), /inside --repo/);
});

test('the CLI refuses to overwrite an existing manifest', t => {
  const root = fixture(t, "import {test} from '@playwright/test'; test('one', () => {});");
  const output = path.join(root, 'manifest.json');
  fs.writeFileSync(output, 'preserve me');
  const script = fileURLToPath(new URL('./scan.mjs', import.meta.url));
  const result = spawnSync(process.execPath, [script, root, '--repo', root, '--typescript', process.env.E2E_REPORT_TYPESCRIPT ?? createCompilerPath(), '--output', output], { encoding: 'utf8' });
  assert.notEqual(result.status, 0);
  assert.equal(fs.readFileSync(output, 'utf8'), 'preserve me');
});

function createCompilerPath() {
  return ts.sys.getExecutingFilePath();
}
