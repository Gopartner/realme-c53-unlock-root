#!/bin/bash
# Root Realme C53 with KernelSU (LKM Mode)
#
# Run this script from the repo root directory:
#   ./scripts/root_kernelsu.sh
#
# NOTE: Pre-built kernelsu.ko modules are incompatible with this device's
# kernel (5.15.178). You MUST build from kernel source.
#
# Prerequisites:
# - Linux environment (WSL, VM, or native) with cross-compiler
# - Kernel source cloned from realme open source
# - stock_boot.img in current directory (from backup.sh)

set -e

KERNEL_SRC_DIR="./kernel_source"
STOCK_BOOT="./stock_boot.img"
PATCHED_BOOT="./kernelsu_patched_boot.img"
MAGISK_APK="./tools/apk/Magisk-v30.7.apk"

echo "============================================"
echo " Root Realme C53 with KernelSU LKM"
echo "============================================"
echo ""

if [ ! -d "$KERNEL_SRC_DIR" ]; then
    echo "ERROR: Kernel source not found at $KERNEL_SRC_DIR"
    echo ""
    echo "Clone kernel source first:"
    echo "  git clone https://github.com/realme-kernel-openspace/"
    echo "    realme_C51_C53_Note50_C60_C51_N53-AndroidU-kernel-source.git"
    echo "    $KERNEL_SRC_DIR"
    echo ""
    echo "NOTE: Clone on Linux/WSL (repo has aux.c/aux.h reserved on Windows)"
    exit 1
fi

echo "[1/5] Adding KernelSU to kernel source..."
cd "$KERNEL_SRC_DIR"
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/main/kernel/setup.sh" | bash -

echo "[2/5] Configuring kernel..."
make ARCH=arm64 CC=clang LLVM=1 vendor/ums9230_defconfig

echo "[3/5] Building KernelSU module..."
make ARCH=arm64 CC=clang LLVM=1 modules_prepare
make ARCH=arm64 CC=clang LLVM=1 M=KernelSU modules
cp KernelSU/kernelsu.ko ../kernelsu.ko
cd ..

echo "[4/5] Patching boot image..."
# Push files to phone
adb shell mkdir -p /data/local/tmp
export MSYS2_ARG_CONV_EXCL="*"
adb push "$STOCK_BOOT" /data/local/tmp/boot.img
adb push kernelsu.ko /data/local/tmp/kernelsu.ko

# Extract magiskboot from Magisk APK (needed by ksud for boot image manipulation)
unzip -o "$MAGISK_APK" "lib/arm64-v8a/libmagiskboot.so" -d /tmp/ksu_tmp/
adb push /tmp/ksu_tmp/lib/arm64-v8a/libmagiskboot.so /data/local/tmp/magiskboot
adb shell chmod 755 /data/local/tmp/magiskboot

# Download ksud for Android
curl -LSs "https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.2.0/ksud-aarch64-linux-android" -o ksud
chmod +x ksud
adb push ksud /data/local/tmp/ksud
adb shell chmod 755 /data/local/tmp/ksud

# Patch boot image with KernelSU LKM
adb shell /data/local/tmp/ksud boot-patch \
    -b /data/local/tmp/boot.img \
    -m /data/local/tmp/kernelsu.ko \
    --magiskboot /data/local/tmp/magiskboot \
    -o /data/local/tmp/ --out-name kernelsu_patched_boot.img

adb pull /data/local/tmp/kernelsu_patched_boot.img "$PATCHED_BOOT"

echo "[5/5] Flashing patched boot to both slots..."
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
echo "  1. Open KernelSU Next app"
echo "  2. Grant root permission to 'Shell'"
echo ""
echo "Verify:"
echo "  adb shell lsmod | grep kernelsu"
echo "  adb shell su -c id"
echo "  -> uid=0(root)"
