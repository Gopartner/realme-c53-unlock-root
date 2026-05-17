#!/bin/bash
# Root Realme C53 with KernelSU (LKM Mode)
#
# Run this script from the repo root directory:
#   ./scripts/root_kernelsu.sh
#
# Prerequisites:
# - Bootloader unlocked
# - stock_boot.img in current directory (from ./scripts/backup.sh)
# - kernelsu.ko built from CI or local build
#
# Building kernelsu.ko:
#   Option A: Download from GitHub Actions artifacts
#   Option B: Build locally on Linux — see .github/workflows/build_kernelsu_module.yml
#
# IMPORTANT: The kernelsu.ko MUST match the device kernel vermagic.
# Check device vermagic:
#   adb shell 'cat /proc/version | grep -o "5\.15\.[^ ]*"'

set -e

KERNELSU_KO="${KERNELSU_KO:-./kernelsu.ko}"
STOCK_BOOT="${STOCK_BOOT:-./stock_boot.img}"
PATCHED_BOOT="${PATCHED_BOOT:-./kernelsu_patched_boot.img}"
KSUD_BIN="${KSUD_BIN:-./ksud}"

echo "============================================"
echo " Root Realme C53 with KernelSU LKM"
echo "============================================"
echo ""

if [ ! -f "$KERNELSU_KO" ]; then
    echo "ERROR: kernelsu.ko not found at $KERNELSU_KO"
    echo ""
    echo "Build kernelsu.ko first:"
    echo "  1. Go to https://github.com/Gopartner/realme-c53-unlock-root/actions"
    echo "  2. Run 'Build KernelSU LKM' workflow"
    echo "  3. Download artifact -> extract kernelsu.ko to repo root"
    echo ""
    echo "OR build manually on Linux:"
    echo "  Follow steps in .github/workflows/build_kernelsu_module.yml"
    exit 1
fi

if [ ! -f "$STOCK_BOOT" ]; then
    echo "ERROR: stock_boot.img not found. Run ./scripts/backup.sh first."
    exit 1
fi

# Check device vermagic match
echo "[CHECK] Verifying vermagic..."
MOD_VERMAGIC=$(modinfo -F vermagic "$KERNELSU_KO" 2>/dev/null || strings "$KERNELSU_KO" | grep -oP '5\.15\.\d+[^ ]*(?= )' | head -1)
echo " Module vermagic: $MOD_VERMAGIC"
echo " Device kernel:   $(adb shell 'uname -r' 2>/dev/null || echo '(phone not connected)')"
echo ""

echo "[1/5] Pushing files to phone..."
export MSYS2_ARG_CONV_EXCL="*"
adb shell mkdir -p /data/local/tmp/ksu
adb push "$STOCK_BOOT" /data/local/tmp/boot.img
adb push "$KERNELSU_KO" /data/local/tmp/ksu/kernelsu.ko

echo "[2/5] Extracting magiskboot from Magisk APK..."
MAGISK_APK="./tools/apk/Magisk-v30.7.apk"
rm -rf /tmp/ksu_tmp
unzip -o "$MAGISK_APK" "lib/arm64-v8a/libmagiskboot.so" -d /tmp/ksu_tmp/
adb push /tmp/ksu_tmp/lib/arm64-v8a/libmagiskboot.so /data/local/tmp/magiskboot
adb shell chmod 755 /data/local/tmp/magiskboot

echo "[3/5] Patching boot image with KernelSU..."
# Check if ksud binary exists locally; if not, download it
if [ ! -f "$KSUD_BIN" ]; then
    echo " Downloading ksud for Android..."
    KSUD_URL=$(curl -s https://api.github.com/repos/KernelSU-Next/KernelSU-Next/releases/latest \
      | grep "ksud-aarch64-linux-android" | grep browser_download_url | cut -d'"' -f4)
    if [ -n "$KSUD_URL" ]; then
        curl -LSs "$KSUD_URL" -o ksud
    else
        echo " WARN: Could not get latest ksud URL, trying fallback..."
        curl -LSs "https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.2.0/ksud-aarch64-linux-android" -o ksud
    fi
    chmod +x ksud
fi
adb push ksud /data/local/tmp/ksud
adb shell chmod 755 /data/local/tmp/ksud

# Patch boot with KernelSU LKM
adb shell /data/local/tmp/ksud boot-patch \
    -b /data/local/tmp/boot.img \
    -m /data/local/tmp/ksu/kernelsu.ko \
    --magiskboot /data/local/tmp/magiskboot \
    -o /data/local/tmp/ \
    --out-name kernelsu_patched_boot.img

adb pull /data/local/tmp/kernelsu_patched_boot.img "$PATCHED_BOOT"

echo "[4/5] Flashing patched boot to both slots..."
adb reboot bootloader
sleep 3
fastboot flash boot_a "$PATCHED_BOOT"
fastboot flash boot_b "$PATCHED_BOOT"
fastboot reboot

echo ""
echo "============================================"
echo " DONE!"
echo "============================================"
echo ""
echo "After phone reboots:"
echo "  1. Install KernelSU Next APK:"
echo "     adb install tools/apk/KernelSU_Next.apk"
echo "  2. Open KernelSU Next app"
echo "  3. Grant root permission to 'Shell'"
echo ""
echo "Verify:"
echo "  adb shell lsmod | grep kernelsu"
echo "  adb shell su -c id"
echo "  -> uid=0(root)"
echo ""
echo "If module fails to load (vermagic mismatch):"
echo "  adb shell insmod -f /data/local/tmp/ksu/kernelsu.ko"
echo "  Check vermagic on device:"
echo "  adb shell 'cat /proc/version'"
echo "  Rebuild with: CONFIG_LOCALVERSION=\"<suffix-from-uname>\""
