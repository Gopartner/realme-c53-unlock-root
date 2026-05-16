#!/bin/bash
# Backup Realme C53 data before unlocking bootloader
#
# Unlocking wipes the device. Run this FIRST to save your data.

set -e

BACKUP_DIR="./backup_$(date +%Y%m%d_%H%M%S)"

echo "=== Realme C53 Backup Script ==="
echo "Destination: $BACKUP_DIR"
echo ""

# Check ADB connection
adb get-state > /dev/null 2>&1 || { echo "ERROR: No device connected"; exit 1; }

mkdir -p "$BACKUP_DIR"

echo "[1/4] Backing up media files..."
adb shell mkdir -p /sdcard/backup_media
for dir in DCIM Pictures Download WhatsApp Movies Music Documents; do
    adb shell "cp -r /sdcard/$dir /sdcard/backup_media/ 2>/dev/null" || true
done
adb pull /sdcard/backup_media/ "$BACKUP_DIR/media/"

echo "[2/4] Dumping app list..."
adb shell pm list packages -3 > "$BACKUP_DIR/user_apps.txt"

echo "[3/4] Dumping bootchain partitions..."
mkdir -p "$BACKUP_DIR/partitions"
adb shell "dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.bin 2>/dev/null"
adb pull /data/local/tmp/boot.bin "$BACKUP_DIR/partitions/stock_boot.img"

echo "[4/4] Saving build info..."
adb shell getprop ro.build.fingerprint > "$BACKUP_DIR/build_fingerprint.txt"
adb shell getprop ro.build.version.release > "$BACKUP_DIR/android_version.txt"
adb shell cat /proc/version > "$BACKUP_DIR/kernel_version.txt"

echo ""
echo "=== Backup Complete ==="
echo "All data saved to: $BACKUP_DIR"
echo ""
echo "Now you can proceed with bootloader unlock."
echo "After unlock, copy media back to the device."
