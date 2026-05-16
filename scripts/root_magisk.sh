#!/bin/bash
# Root Realme C53 with Magisk
#
# Prerequisites:
# 1. Bootloader unlocked
# 2. Stock boot image dumped as stock_boot.img
# 3. Magisk APK downloaded (v30.7+)
# 4. ADB debugging enabled

set -e

MAGISK_APK="../tools/apk/Magisk-v30.7.apk"
STOCK_BOOT="../images/stock_boot.img"
PATCHED_BOOT="../magisk_patched_boot.img"

echo "=== Root Realme C53 with Magisk ==="

# Check files
for f in "$MAGISK_APK" "$STOCK_BOOT"; do
    if [ ! -f "$f" ]; then
        echo "ERROR: $f not found"
        exit 1
    fi
done

echo "[1/5] Installing Magisk app..."
adb install "$MAGISK_APK"

echo "[2/5] Extracting Magisk files from APK..."
mkdir -p magisk_files
unzip -o "$MAGISK_APK" "lib/arm64-v8a/*" "assets/*" -d magisk_files/

echo "[3/5] Pushing files to phone..."
adb shell mkdir -p /data/local/tmp/magisk
export MSYS2_ARG_CONV_EXCL="*"  # Required on Git Bash for Windows

for src in \
    "magisk_files/assets/boot_patch.sh" \
    "magisk_files/assets/util_functions.sh" \
    "magisk_files/assets/addon.d.sh" \
    "magisk_files/assets/module_installer.sh" \
    "magisk_files/assets/stub.apk" \
    "magisk_files/lib/arm64-v8a/libmagiskboot.so" \
    "magisk_files/lib/arm64-v8a/libmagiskinit.so" \
    "magisk_files/lib/arm64-v8a/libmagisk.so" \
    "magisk_files/lib/arm64-v8a/libmagiskpolicy.so" \
    "magisk_files/lib/arm64-v8a/libbusybox.so" \
    "magisk_files/lib/arm64-v8a/libinit-ld.so"; do
    
    dest="/data/local/tmp/magisk/$(basename $src .so)"
    [ "$(basename $src)" = "boot_patch.sh" ] && dest="/data/local/tmp/magisk/boot_patch.sh"
    [ "$(basename $src)" = "util_functions.sh" ] && dest="/data/local/tmp/magisk/util_functions.sh"
    [ "$(basename $src)" = "addon.d.sh" ] && dest="/data/local/tmp/magisk/addon.d.sh"
    [ "$(basename $src)" = "module_installer.sh" ] && dest="/data/local/tmp/magisk/module_installer.sh"
    [ "$(basename $src)" = "stub.apk" ] && dest="/data/local/tmp/magisk/stub.apk"
    [ "$(basename $src)" = "libinit-ld.so" ] && dest="/data/local/tmp/magisk/init-ld"
    
    adb push "$src" "$dest"
done

adb shell chmod 755 /data/local/tmp/magisk/*

echo "[4/5] Patching boot image..."
adb push "$STOCK_BOOT" /data/local/tmp/boot.img
adb shell /data/local/tmp/magisk/boot_patch.sh /data/local/tmp/boot.img
adb pull /data/local/tmp/magisk/new-boot.img "$PATCHED_BOOT"

echo "[5/5] Flashing patched boot..."
adb reboot bootloader
sleep 3
fastboot flash boot_a "$PATCHED_BOOT"
fastboot flash boot_b "$PATCHED_BOOT"
fastboot reboot

echo ""
echo "=== DONE ==="
echo "Phone is rebooting. After boot:"
echo "1. Open Magisk app"
echo "2. Go to Superuser tab"
echo "3. Grant root to 'Shell'"
echo ""
echo "Verify with: adb shell su -c id"
echo "Expected: uid=0(root)"
