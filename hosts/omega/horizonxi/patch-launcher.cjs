const fs = require('node:fs');

const originalImport = 'n=t[r].value.split(",").map(Number);c.persistentStorage.set("registrySettings.padsin000"';
const patchedImport = 'n=t[r].value.split(",").map(Number);const selectedGamepad=t.find(entry=>entry.name==="padguid000");selectedGamepad&&selectedGamepad.value&&c.persistentStorage.set("registrySettings.padguid000",{name:"Gamepad Device ID",key:"padguid000",value:selectedGamepad.value});c.persistentStorage.set("registrySettings.padsin000"';

function patchLauncher(source) {
  const originalCount = source.split(originalImport).length - 1;
  const patchedCount = source.split(patchedImport).length - 1;
  if (patchedCount === 1 && originalCount === 0) return source;
  if (originalCount !== 1 || patchedCount !== 0) {
    throw new Error('Unsupported HorizonXI gamepad import; review the launcher update before patching.');
  }
  return source.replace(originalImport, patchedImport);
}

function patchLauncherFile(bundlePath) {
  const source = fs.readFileSync(bundlePath, 'utf8');
  const patched = patchLauncher(source);
  if (patched === source) return false;
  const backupPath = `${bundlePath}.before-gamepad-sync`;
  if (!fs.existsSync(backupPath)) {
    fs.copyFileSync(bundlePath, backupPath, fs.constants.COPYFILE_EXCL);
  }
  fs.writeFileSync(bundlePath, patched);
  return true;
}

if (require.main === module) {
  try {
    const bundlePath = process.argv[2];
    if (!bundlePath) throw new Error('Usage: patch-launcher.cjs <launcher index.js>');
    if (patchLauncherFile(bundlePath)) console.log(`Enabled gamepad device-ID import: ${bundlePath}`);
  } catch (error) {
    console.error(`HorizonXI controller setup: ${error.message}`);
    process.exitCode = 1;
  }
}

module.exports = { patchLauncher, patchLauncherFile };
