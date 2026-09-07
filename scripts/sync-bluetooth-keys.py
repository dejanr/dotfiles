#!/usr/bin/env python3

import argparse
import configparser
from dataclasses import dataclass
import fcntl
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import sys
import tempfile

BLUETOOTH_STATE = Path("/var/lib/bluetooth")
BACKUP_ROOT = Path("/var/backups")


class SyncError(Exception):
    pass


@dataclass
class Update:
    path: Path
    original: bytes
    updated: bytes


def mac_address(value):
    if not re.fullmatch(r"(?:[0-9a-fA-F]{2}:){5}[0-9a-fA-F]{2}", value):
        raise argparse.ArgumentTypeError("Expected a colon-separated Bluetooth MAC address")
    return value.upper()


def run(*command):
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode:
        raise SyncError(f"{Path(command[0]).name} failed; output withheld to protect pairing keys")
    return result.stdout


def registry_values(export):
    export = re.sub(r"\\\r?\n[ \t]*", "", export)
    return dict(re.findall(r'^"([^"\n]+)"=(.*)$', export, re.M))


def windows_keys(hive, adapter, devices):
    with hive.open("rb") as stream:
        header = stream.read(12)
    if len(header) != 12 or header[:4] != b"regf":
        raise SyncError("Not a Windows registry hive")
    first, second = struct.unpack_from("<II", header, 4)
    if first != second:
        raise SyncError(
            "Windows registry has unapplied transaction logs. Boot Windows, disable Fast Startup, "
            "and fully shut down before retrying. Do not copy potentially stale keys."
        )

    def export(path):
        return registry_values(run("hivexregedit", "--export", "--max-depth", "1", str(hive), path))

    current = export(r"\Select").get("Current", "")
    if not re.fullmatch(r"dword:[0-9a-fA-F]{8}", current):
        raise SyncError("Cannot determine the active Windows ControlSet")
    control_set = f"ControlSet{int(current.split(':')[1], 16):03d}"
    values = export(
        f"\\{control_set}\\Services\\BTHPORT\\Parameters\\Keys\\"
        + adapter.replace(":", "").lower()
    )
    values = {name.lower(): value for name, value in values.items()}
    keys = {}
    for device in devices:
        value = values.get(device.replace(":", "").lower(), "")
        match = re.fullmatch(r"hex(?:\(3\))?:((?:[0-9a-fA-F]{2},){15}[0-9a-fA-F]{2})", value)
        if match is None:
            raise SyncError(f"Missing or invalid 16-byte Windows Classic Bluetooth key for {device}")
        keys[device] = match[1].replace(",", "").upper()
    return keys


def prepare_updates(adapter, keys):
    updates = []
    for device, key in keys.items():
        path = BLUETOOTH_STATE / adapter / device / "info"
        original = path.read_bytes()
        text = original.decode("utf-8")
        config = configparser.ConfigParser(interpolation=None)
        config.read_string(text)
        if not config.has_option("LinkKey", "Key"):
            raise SyncError(f"{device}: no Classic Bluetooth LinkKey; pair in Linux first")
        old_key = config["LinkKey"]["Key"]
        if not re.fullmatch(r"[0-9a-fA-F]{32}", old_key):
            raise SyncError(f"{device}: invalid Linux LinkKey")
        if old_key.upper() == key:
            print(f"{device}: keys already match")
            continue
        section = re.search(r"(?ms)^\[LinkKey\]\r?\n.*?(?=^\[|\Z)", text)
        if section is None:
            raise SyncError(f"{device}: cannot locate LinkKey section")
        replacement, count = re.subn(
            r"(?m)^(Key=)[0-9a-fA-F]{32}(?=\r?$)",
            lambda match: match[1] + key,
            section[0],
        )
        if count != 1:
            raise SyncError(f"{device}: cannot safely replace LinkKey")
        updated = (text[:section.start()] + replacement + text[section.end():]).encode("utf-8")
        updates.append(Update(path, original, updated))
        print(f"{device}: pairing key needs updating")
    return updates


def atomic_write(path, content):
    metadata = path.stat()
    descriptor, temporary = tempfile.mkstemp(prefix=".key-sync-", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as stream:
            os.fchown(stream.fileno(), metadata.st_uid, metadata.st_gid)
            os.fchmod(stream.fileno(), metadata.st_mode & 0o777)
            stream.write(content)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


def apply_keys(adapter, keys):
    if not Path("/sys/module/btusb").exists():
        raise SyncError("Apply currently supports the btusb driver only")
    active = subprocess.run(
        ["systemctl", "is-active", "--quiet", "bluetooth.service"], capture_output=True
    ).returncode == 0
    run("systemctl", "stop", "bluetooth.service")
    written = []
    driver_unloaded = False
    try:
        updates = prepare_updates(adapter, keys)
        if updates:
            BACKUP_ROOT.mkdir(exist_ok=True)
            backup = Path(tempfile.mkdtemp(prefix="bluetooth-key-sync-", dir=BACKUP_ROOT))
            for update in updates:
                shutil.copy2(update.path, backup / (update.path.parent.name + ".info"))
            print(f"Original pairing files backed up to {backup}")
        for update in updates:
            atomic_write(update.path, update.updated)
            written.append(update)
        if prepare_updates(adapter, keys):
            raise SyncError("Pairing key verification failed")
        # A daemon restart or adapter power toggle can leave old link keys cached in the kernel.
        run("modprobe", "-r", "btusb")
        driver_unloaded = True
        run("modprobe", "btusb")
        driver_unloaded = False
    except BaseException:
        for update in reversed(written):
            atomic_write(update.path, update.original)
        raise
    finally:
        try:
            if driver_unloaded:
                run("modprobe", "btusb")
        finally:
            if active:
                run("systemctl", "start", "bluetooth.service")
    print("Shared keys saved and Bluetooth driver reloaded. Windows was not modified.")
    print("For Joy-Cons: tap SYNC once (do not hold), then press a normal button to reconnect.")
    print("A connection test in each OS is still required; do not forget or re-pair the devices.")


def main():
    parser = argparse.ArgumentParser(
        description="Copy Windows Classic Bluetooth keys into existing Linux pairings (dry run by default).",
        epilog="Requires Python 3, hivex, systemd and kmod. See scripts/README.md.",
    )
    parser.add_argument("--hive", required=True, type=Path, help="Windows/System32/config/SYSTEM on a read-only mount")
    parser.add_argument("--adapter", required=True, type=mac_address, help="shared Bluetooth adapter MAC")
    parser.add_argument("--apply", action="store_true", help="back up, update keys, and reload btusb; disconnects ALL USB Bluetooth devices")
    parser.add_argument("devices", nargs="+", type=mac_address, help="device MACs to sync (Classic Bluetooth only)")
    args = parser.parse_args()
    if os.geteuid() != 0:
        raise SyncError("Run as root to access Linux's protected pairing files")
    for command in ("hivexregedit", "systemctl", "modprobe"):
        if shutil.which(command) is None:
            raise SyncError(f"Required command not found: {command}")
    os.umask(0o077)
    with open("/run/lock/bluetooth-key-sync.lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        keys = windows_keys(args.hive, args.adapter, dict.fromkeys(args.devices))
        prepare_updates(args.adapter, keys)
        if args.apply:
            apply_keys(args.adapter, keys)
        else:
            print("Dry run: no pairing files or services changed. Use --apply to sync and reload btusb.")


if __name__ == "__main__":
    try:
        main()
    except SyncError as error:
        sys.exit(str(error))
    except (OSError, configparser.Error, UnicodeError):
        sys.exit("Cannot safely read or update pairing state; details withheld to protect keys.")
