#!/bin/bash
# Root Realme C53 with KernelSU (LKM Mode)
#
# Note: Pre-built kernelsu.ko modules are incompatible with this device's
# kernel version (5.15.178). You MUST build from source.
#
# Prerequisites:
# - Linux environment (WSL, VM, or native)
# - Kernel source cloned
# - Cross-compiler (aarch64-linux-android- clang)

set -e

KERNEL_SOURCE="./realme_C51_C53_Note50_C60_C51_N53-AndroidU-kernel-source"
STOCK_BOOT="../stock_boot.img"
PATCHED_BOOT="../kernelsu_patched_boot.img"

echo "=== Root Realme C53 with KernelSU LKM ==="

echo "[1/5] Adding KernelSU to kernel source..."
cd "$KERNEL_SOURCE"
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/main/kernel/setup.sh" | bash -

echo "[2/5] Configuring kernel..."
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-android- CC=clang LLVM=1 \
    vendor/ums9230_defconfig

echo "[3/5] Building KernelSU module..."
make ARCH=arm64 CC=clang LLVM=1 modules_prepare
make ARCH=arm64 CC=clang LLVM=1 M=KernelSU modules

echo "[4/5] Patching boot image..."
cp KernelSU/kernelsu.ko ../kernelsu.ko
cd ..  # Back to working dir

# Download ksud for Android
curl -LSsO "https://github.com/KernelSU-Next/KernelSU-Next/releases/download/v3.2.0/ksud-aarch64-linux-android"
chmod +x ksud-aarch64-linux-android

# Push to phone
adb push "$STOCK_BOOT" /data/local/tmp/boot.img
adb push kernelsu.ko /data/local/tmp/kernelsu.ko
adb push ksud-aarch64-linux-android /data/local/tmp/ksud
adb shell chmod 755 /data/local/tmp/ksud

# Extract magiskboot from Magisk APK for boot image manipulation
unzip -o "$MAGISK_APK" "lib/arm64-v8a/libmagiskboot.so" -d tmp/
adb push tmp/lib/arm64-v8a/libmagiskboot.so /data/local/tmp/magiskboot
adb shell chmod 755 /data/local/tmp/magiskboot

# Patch boot image
adb shell /data/local/tmp/ksud boot-patch \
    -b /data/local/tmp/boot.img \
    -m /data/local/tmp/kernelsu.ko \
    --magiskboot /data/local/tmp/magiskboot \
    -o /data/local/tmp/ \
    --out-name kernelsu_patched_boot.img

adb pull /data/local/tmp/kernelsu_patched_boot.img "$PATCHED_BOOT"

echo "[5/5] Flashing patched boot..."
adb reboot bootloader
sleep 3
fastboot flash boot_a "$PATCHED_BOOT"
fastboot flash boot_b "$PATCHED_BOOT"
fastboot reboot

echo ""
echo "=== DONE ==="
echo "Phone rebooting. After boot:"
echo "1. Open KernelSU Next app"
echo "2. Grant root to Shell"
echo ""

# Verify
echo "Verify:"
echo "  adb shell lsmod | grep kernelsu   # should show module loaded"
echo "  adb shell su -c id                # uid=0(root)"
