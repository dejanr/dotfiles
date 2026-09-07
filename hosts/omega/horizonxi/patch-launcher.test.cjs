const assert = require('node:assert/strict');
const { test } = require('node:test');
const vm = require('node:vm');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { patchLauncher, patchLauncherFile } = require('./patch-launcher.cjs');

const registryImport = 'function(e,t){if(e){if(1==e.code)throw e;throw e}{const e=t.findIndex(e=>"padmode000"===e.name),r=t.findIndex(e=>"padsin000"===e.name),n=t[r].value.split(",").map(Number);c.persistentStorage.set("registrySettings.padsin000",{name:"Button Mappings",key:"padsin000",value:n});const s=t[e].value.split(",").map(Number);return void c.persistentStorage.set("registrySettings.padmode000",{name:"Gamepad Settings Controls",key:"padmode000",value:s})}}';
const deviceId = '{9E573ED2-7734-11D2-8D4A-23903FB6BDF7}';
const registryValues = [
  { name: 'padmode000', value: '1,1,0,0,0,1' },
  { name: 'padsin000', value: '8,9,13,12' },
  { name: 'padguid000', value: deviceId },
];

function createImport() {
  const saved = {};
  const importRegistry = vm.runInNewContext(`(${patchLauncher(registryImport)})`, {
    c: {
      persistentStorage: {
        set(key, value) {
          saved[key] = JSON.parse(JSON.stringify(value));
        },
      },
    },
  });
  return { saved, importRegistry };
}

test('the launcher imports the selected device ID and existing button settings', () => {
  const { saved, importRegistry } = createImport();
  importRegistry(null, registryValues);
  assert.deepEqual(saved['registrySettings.padguid000'], {
    name: 'Gamepad Device ID', key: 'padguid000', value: deviceId,
  });
  assert.deepEqual(saved['registrySettings.padmode000'].value, [1, 1, 0, 0, 0, 1]);
  assert.deepEqual(saved['registrySettings.padsin000'].value, [8, 9, 13, 12]);
});

test('saving a new selection replaces the previous device ID', () => {
  const { saved, importRegistry } = createImport();
  importRegistry(null, registryValues);
  const nextId = '{9E573EDE-7734-11D2-8D4A-23903FB6BDF7}';
  importRegistry(null, registryValues.map(entry => entry.name === 'padguid000' ? { ...entry, value: nextId } : entry));
  assert.equal(saved['registrySettings.padguid000'].value, nextId);
});

test('an absent or empty device ID does not erase the last selection', () => {
  const { saved, importRegistry } = createImport();
  importRegistry(null, registryValues);
  importRegistry(null, registryValues.filter(entry => entry.name !== 'padguid000'));
  importRegistry(null, registryValues.map(entry => entry.name === 'padguid000' ? { ...entry, value: '' } : entry));
  assert.equal(saved['registrySettings.padguid000'].value, deviceId);
});

test('registry errors are still propagated', () => {
  const { importRegistry } = createImport();
  const error = { code: 1 };
  assert.throws(() => importRegistry(error, []), value => value === error);
});

test('repeated launches do not insert the patch twice', () => {
  const patched = patchLauncher(registryImport);
  assert.equal(patchLauncher(patched), patched);
});

test('unknown or ambiguous launcher layouts are rejected', () => {
  assert.throws(() => patchLauncher('different launcher version'), /Unsupported.*import/);
  assert.throws(() => patchLauncher(registryImport + registryImport), /Unsupported.*import/);
  assert.throws(() => patchLauncher(patchLauncher(registryImport) + registryImport), /Unsupported.*import/);
});

test('patching a new launcher version backs it up and leaves repeat launches untouched', t => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'horizonxi-launcher-'));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const bundlePath = path.join(directory, 'index.js');
  fs.writeFileSync(bundlePath, registryImport);
  assert.equal(patchLauncherFile(bundlePath), true);
  assert.equal(fs.readFileSync(`${bundlePath}.before-gamepad-sync`, 'utf8'), registryImport);
  const firstWrite = fs.statSync(bundlePath).mtimeMs;
  assert.equal(patchLauncherFile(bundlePath), false);
  assert.equal(fs.statSync(bundlePath).mtimeMs, firstWrite);
  assert.equal(fs.readFileSync(bundlePath, 'utf8'), patchLauncher(registryImport));
});

test('an unsupported update is not modified', t => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), 'horizonxi-launcher-'));
  t.after(() => fs.rmSync(directory, { recursive: true, force: true }));
  const bundlePath = path.join(directory, 'index.js');
  fs.writeFileSync(bundlePath, 'new launcher layout');
  assert.throws(() => patchLauncherFile(bundlePath), /Unsupported.*import/);
  assert.equal(fs.readFileSync(bundlePath, 'utf8'), 'new launcher layout');
  assert.equal(fs.existsSync(`${bundlePath}.before-gamepad-sync`), false);
});
