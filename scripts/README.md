# Maintenance scripts

## Shared Bluetooth pairing for Windows/Linux dual boot

`sync-bluetooth-keys.py` copies Windows **Classic Bluetooth** link keys into existing
Linux pairings. It supports Joy-Cons and other Classic Bluetooth devices using the
same adapter in both OSes. BLE devices and non-`btusb` adapters are not supported.

Pair in Linux first, then pair in Windows last. Do not re-pair in Linux before
syncing: the device must still hold the Windows key. Once synchronized, normal
reboots and OS switching should not require another sync. Explicitly forgetting
and re-pairing a device can change its key and require another sync.

### Run

Leave the controllers asleep while syncing. Use a wired keyboard/mouse:
`--apply` disconnects **all devices on all `btusb` adapters**, not just the devices
being synchronized.

1. Fully shut down Windows with Fast Startup disabled. The script refuses registry
   hives with unapplied transaction logs instead of silently importing stale keys.
   It does not replay Windows registry logs or modify the Windows installation.
2. Identify the Windows partition with `lsblk -f` and mount it read-only. Replace
   `/dev/WINDOWS_PARTITION` below with its actual device path:

   ```bash
   sudo mkdir -p /mnt/windows-bt-sync
   sudo mount -t ntfs3 -o ro,nosuid,nodev,noexec /dev/WINDOWS_PARTITION /mnt/windows-bt-sync
   ```

   Do not force-mount a hibernated volume or remove its hibernation file.
   BitLocker volumes must already be unlocked.
3. From the repository root, enter a shell with the dependencies:

   ```bash
   nix shell nixpkgs#python3 nixpkgs#hivex nixpkgs#kmod nixpkgs#systemd
   ```

4. Dry-run the comparison. Replace these fictional MAC addresses with your shared
   adapter and device addresses:

   ```bash
   sudo env PATH="$PATH" python3 scripts/sync-bluetooth-keys.py \
     --hive /mnt/windows-bt-sync/Windows/System32/config/SYSTEM \
     --adapter AA:BB:CC:DD:EE:FF \
     11:22:33:44:55:66 22:33:44:55:66:77
   ```

5. Repeat with `--apply` to write the keys and reload the driver. This also reloads
   the driver when the keys already match, which is useful after an earlier sync
   that left old keys cached in the kernel.
6. For each Joy-Con, **tap SYNC once and release immediately**, then press a normal
   button to wake it. Do not hold SYNC (pairing mode). Verify it stays connected and
   works as an input device. Later, verify reconnection in Windows without re-pairing.
7. Unmount the temporary Windows mount:

   ```bash
   sudo umount /mnt/windows-bt-sync
   sudo rmdir /mnt/windows-bt-sync
   ```

### Safety and recovery

- Dry run is the default. Keys are never printed or stored in the repository.
- Only the selected devices' `[LinkKey] Key=` values change. Other settings and
  file ownership/permissions are preserved.
- Original pairing files are backed up in a root-only
  `/var/backups/bluetooth-key-sync-*` directory before writing. Treat these as secrets.
- Failed writes or driver reloads trigger rollback of modified files. The script
  attempts to restore the driver and the Bluetooth service's prior running state.
- To restore manually, stop `bluetooth.service`, copy each backup `.info` file to
  `/var/lib/bluetooth/<adapter>/<device>/info` preserving ownership and permissions,
  then reboot to clear cached keys. Restoring an old key does not change the key
  held by the controller.

### Why the driver reload matters

During the Joy-Con diagnosis, restarting `bluetooth.service` and toggling adapter
power left the PC sending a key different from the updated key on disk. Reloading
`btusb`, followed by a brief SYNC tap on the controller, resulted in the shared key
being sent, successful encryption, and `joycond` detecting the controller.

The initial Windows registry hive also had unapplied logs. Recovering those logs
read-only showed the same pairing keys, so stale registry data was ruled out in
that session. This script deliberately refuses dirty hives rather than bundling a
registry recovery tool.

Reference: [ArchWiki: dual-boot pairing](https://wiki.archlinux.org/title/Bluetooth#Dual_boot_pairing).

Run the script's tests without root or Bluetooth hardware:

```bash
python3 -m unittest discover -s scripts/tests -v
```
