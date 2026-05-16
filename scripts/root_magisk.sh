#!/bin/bash
# Root Realme C53 with Magisk
#
# Run this script from the repo root directory:
#   ./scripts/root_magisk.sh
#
# Prerequisites:
# 1. Bootloader unlocked
# 2. stock_boot.img in current directory (from ./scripts/backup.sh)
# 3. USB debugging enabled on phone

set -e

MAGISK_APK="./tools/apk/Magisk-v30.7.apk"
STOCK_BOOT="./stock_boot.img"
PATCHED_BOOT="./magisk_patched_boot.img"

echo "============================================"
echo " Root Realme C53 with Magisk"
echo "============================================"
echo ""

if [ ! -f "$MAGISK_APK" ]; then echo "ERROR: $MAGISK_APK not found"; exit 1; fi
if [ ! -f "$STOCK_BOOT" ]; then echo "ERROR: $STOCK_BOOT not found. Run backup.sh first."; exit 1; fi

echo "[1/5] Installing Magisk app on phone..."
adb install "$MAGISK_APK"

echo "[2/5] Extracting Magisk files from APK..."
rm -rf magisk_files
unzip -o "$MAGISK_APK" "lib/arm64-v8a/*" "assets/*" -d magisk_files/

echo "[3/5] Pushing files to phone..."
adb shell mkdir -p /data/local/tmp/magisk

export MSYS2_ARG_CONV_EXCL="*"
adb push magisk_files/assets/boot_patch.sh /data/local/tmp/magisk/boot_patch.sh
adb push magisk_files/assets/util_functions.sh /data/local/tmp/magisk/util_functions.sh
adb push magisk_files/assets/addon.d.sh /data/local/tmp/magisk/addon.d.sh
adb push magisk_files/assets/module_installer.sh /data/local/tmp/magisk/module_installer.sh
adb push magisk_files/assets/stub.apk /data/local/tmp/magisk/stub.apk
adb push magisk_files/lib/arm64-v8a/libmagiskboot.so /data/local/tmp/magisk/magiskboot
adb push magisk_files/lib/arm64-v8a/libmagiskinit.so /data/local/tmp/magisk/magiskinit
adb push magisk_files/lib/arm64-v8a/libmagisk.so /data/local/tmp/magisk/magisk
adb push magisk_files/lib/arm64-v8a/libmagiskpolicy.so /data/local/tmp/magisk/magiskpolicy
adb push magisk_files/lib/arm64-v8a/libbusybox.so /data/local/tmp/magisk/busybox
adb push magisk_files/lib/arm64-v8a/libinit-ld.so /data/local/tmp/magisk/init-ld
adb shell chmod 755 /data/local/tmp/magisk/*

echo "[4/5] Patching boot image with Magisk..."
adb push "$STOCK_BOOT" /data/local/tmp/boot.img
adb shell /data/local/tmp/magisk/boot_patch.sh /data/local/tmp/boot.img
adb pull /data/local/tmp/magisk/new-boot.img "$PATCHED_BOOT"

echo "[5/5] Flashing patched boot to both slots..."
adb reboot bootloader
sleep 3
fastboot flash boot_a "$PATCHED_BOOT"
fastboot flash boot_b "$PATCHED_BOOT"
fastboot reboot

echo ""
echo "============================================"
echo " DONE! Root should be working."
echo "============================================"
echo ""
echo "After phone reboots:"
echo "  1. Open Magisk app on phone"
echo "  2. Go to Superuser tab"
echo "  3. Grant root permission to 'Shell'"
echo ""
echo "Verify:"
echo "  adb shell su -c id"
echo "  -> uid=0(root)"
