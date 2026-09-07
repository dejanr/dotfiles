import importlib.util
from pathlib import Path
import stat
import struct
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location(
    "sync_bluetooth_keys", Path(__file__).parents[1] / "sync-bluetooth-keys.py"
)
sync = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = sync
spec.loader.exec_module(sync)

ADAPTER = "AA:BB:CC:DD:EE:FF"
DEVICE = "11:22:33:44:55:66"
OTHER_DEVICE = "22:33:44:55:66:77"
OLD_KEY = "01" * 16
NEW_KEY = "02" * 16
INFO = (
    "[General]\nName=Joy-Con (R)\nTrusted=true\n\n"
    f"[LinkKey]\nKey={OLD_KEY}\nType=4\nPINLength=0\n\n"
    "[DeviceID]\nSource=2\nVendor=1406\n"
).encode()


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.state = self.root / "bluetooth"
        self.backups = self.root / "backups"
        self.path = self.state / ADAPTER / DEVICE / "info"
        self.path.parent.mkdir(parents=True)
        self.path.write_bytes(INFO)
        self.path.chmod(0o640)
        self.hive = self.root / "SYSTEM"
        self.hive.write_bytes(b"regf" + struct.pack("<II", 1, 1))
        for name, value in (("BLUETOOTH_STATE", self.state), ("BACKUP_ROOT", self.backups)):
            patcher = patch.object(sync, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)
        output = patch("builtins.print")
        self.print = output.start()
        self.addCleanup(output.stop)

    def test_classic_registry_formats_and_active_control_set(self):
        for prefix in ("hex:", "hex(3):"):
            with self.subTest(prefix=prefix):
                value = ",".join(["02"] * 8) + ",\\\n  " + ",".join(["02"] * 8)
                exports = ['"Current"=dword:00000002\n', f'"112233445566"={prefix}{value}\n']
                with patch.object(sync, "run", side_effect=exports) as run:
                    keys = sync.windows_keys(self.hive, ADAPTER, [DEVICE])
                self.assertEqual(keys, {DEVICE: NEW_KEY})
                self.assertIn("ControlSet002", run.call_args.args[-1])

    def test_dirty_hive_is_rejected_before_export(self):
        self.hive.write_bytes(b"regf" + struct.pack("<II", 2, 1))
        with patch.object(sync, "run") as run:
            with self.assertRaisesRegex(sync.SyncError, "transaction logs"):
                sync.windows_keys(self.hive, ADAPTER, [DEVICE])
        run.assert_not_called()

    def test_missing_or_invalid_windows_keys_are_rejected(self):
        for value in ("", '"112233445566"=hex(3):01,02\n'):
            with patch.object(sync, "run", side_effect=['"Current"=dword:00000001\n', value]):
                with self.assertRaises(sync.SyncError):
                    sync.windows_keys(self.hive, ADAPTER, [DEVICE])

    def test_dry_run_preserves_files_and_only_plans_link_key_change(self):
        for content in (INFO, INFO.replace(b"\n", b"\r\n")):
            self.path.write_bytes(content)
            updates = sync.prepare_updates(ADAPTER, {DEVICE: NEW_KEY})
            self.assertEqual(len(updates), 1)
            self.assertEqual(updates[0].updated, content.replace(OLD_KEY.encode(), NEW_KEY.encode()))
            self.assertEqual(self.path.read_bytes(), content)
        self.assertFalse(self.backups.exists())
        self.assertNotIn(OLD_KEY, str(self.print.call_args_list))
        self.assertNotIn(NEW_KEY, str(self.print.call_args_list))

    def test_matching_keys_are_idempotent(self):
        self.assertEqual(sync.prepare_updates(ADAPTER, {DEVICE: OLD_KEY}), [])

    def test_missing_linux_device_aborts_before_writes(self):
        with self.assertRaises(FileNotFoundError):
            sync.prepare_updates(ADAPTER, {DEVICE: NEW_KEY, OTHER_DEVICE: NEW_KEY})
        self.assertEqual(self.path.read_bytes(), INFO)

    def test_ble_only_device_is_rejected(self):
        self.path.write_text(f"[LongTermKey]\nKey={OLD_KEY}\n")
        with self.assertRaisesRegex(sync.SyncError, "no Classic Bluetooth"):
            sync.prepare_updates(ADAPTER, {DEVICE: NEW_KEY})

    def apply_with_mocked_hardware(self, keys, run):
        with patch.object(sync.Path, "exists", return_value=True), \
             patch.object(sync.subprocess, "run", return_value=Mock(returncode=0)), \
             patch.object(sync, "run", run):
            sync.apply_keys(ADAPTER, keys)

    def test_apply_backs_up_preserves_metadata_and_reloads_driver(self):
        run = Mock(return_value="")
        before = self.path.stat()
        self.apply_with_mocked_hardware({DEVICE: NEW_KEY}, run)
        self.assertEqual(self.path.read_bytes(), INFO.replace(OLD_KEY.encode(), NEW_KEY.encode()))
        after = self.path.stat()
        self.assertEqual((before.st_mode, before.st_uid, before.st_gid),
                         (after.st_mode, after.st_uid, after.st_gid))
        backup = next(self.backups.glob("bluetooth-key-sync-*"))
        self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o700)
        self.assertEqual((backup / f"{DEVICE}.info").read_bytes(), INFO)
        self.assertEqual([call.args for call in run.call_args_list], [
            ("systemctl", "stop", "bluetooth.service"),
            ("modprobe", "-r", "btusb"),
            ("modprobe", "btusb"),
            ("systemctl", "start", "bluetooth.service"),
        ])

    def test_apply_matching_keys_still_clears_kernel_cache(self):
        run = Mock(return_value="")
        self.apply_with_mocked_hardware({DEVICE: OLD_KEY}, run)
        run.assert_any_call("modprobe", "-r", "btusb")
        self.assertFalse(self.backups.exists())

    def test_driver_failure_rolls_back_and_restores_service(self):
        for failing_command in (("modprobe", "-r", "btusb"), ("modprobe", "btusb")):
            with self.subTest(command=failing_command):
                failed = False

                def command(*args):
                    nonlocal failed
                    if args == failing_command and not failed:
                        failed = True
                        raise sync.SyncError("Simulated driver failure")
                    return ""

                run = Mock(side_effect=command)
                with self.assertRaisesRegex(sync.SyncError, "Simulated"):
                    self.apply_with_mocked_hardware({DEVICE: NEW_KEY}, run)
                self.assertEqual(self.path.read_bytes(), INFO)
                self.assertEqual(run.call_args.args, ("systemctl", "start", "bluetooth.service"))

    def test_second_write_failure_restores_first_device(self):
        other = self.state / ADAPTER / OTHER_DEVICE / "info"
        other.parent.mkdir()
        other.write_bytes(INFO)
        atomic_write = sync.atomic_write

        def write(path, content):
            if path == other:
                raise OSError("Simulated write failure")
            atomic_write(path, content)

        run = Mock(return_value="")
        with patch.object(sync, "atomic_write", side_effect=write):
            with self.assertRaises(OSError):
                self.apply_with_mocked_hardware({DEVICE: NEW_KEY, OTHER_DEVICE: NEW_KEY}, run)
        self.assertEqual(self.path.read_bytes(), INFO)
        self.assertEqual(other.read_bytes(), INFO)
        self.assertEqual(run.call_args.args, ("systemctl", "start", "bluetooth.service"))


if __name__ == "__main__":
    unittest.main()
