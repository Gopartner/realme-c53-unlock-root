#!/bin/bash
# Backup media files from Realme C53 before unlocking bootloader
#
# Unlocking wipes the device. Backup your important data first.

set -e

BACKUP_DIR="./backup_$(date +%Y%m%d_%H%M%S)"

echo "=== Realme C53 Backup Script ==="
echo "Destination: $BACKUP_DIR"
echo ""

adb get-state > /dev/null 2>&1 || { echo "ERROR: No device connected"; exit 1; }

mkdir -p "$BACKUP_DIR"

echo "[1/3] Backing up storage..."
adb shell mkdir -p /sdcard/backup
adb shell cp -r /sdcard/DCIM /sdcard/backup/ 2>/dev/null || true
adb shell cp -r /sdcard/Pictures /sdcard/backup/ 2>/dev/null || true
adb shell cp -r /sdcard/Download /sdcard/backup/ 2>/dev/null || true
adb shell cp -r /sdcard/Movies /sdcard/backup/ 2>/dev/null || true
adb shell cp -r /sdcard/Music /sdcard/backup/ 2>/dev/null || true
adb shell cp -r /sdcard/Documents /sdcard/backup/ 2>/dev/null || true
adb pull /sdcard/backup/ "$BACKUP_DIR/"

echo "[2/3] Dumping stock boot image..."
adb shell "dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.bin 2>/dev/null"
adb pull /data/local/tmp/boot.bin "$BACKUP_DIR/stock_boot.img"
# Also copy to repo images/ for future use
cp "$BACKUP_DIR/stock_boot.img" "../images/stock_boot.img" 2>/dev/null || true

echo "[3/3] Saving build info..."
adb shell getprop ro.build.fingerprint > "$BACKUP_DIR/build_info.txt"

echo ""
echo "=== Done ==="
echo "Files saved to: $BACKUP_DIR"
echo "After unlocking, copy files back to the device."
