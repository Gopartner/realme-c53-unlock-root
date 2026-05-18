#!/bin/bash
# Realme C53 (RMX3760) - Flash KernelSU Boot Image
# Run this from the release folder

set -e

echo "============================================"
echo "Realme C53 KernelSU Flash Tool"
echo "============================================"
echo ""

adb get-state >/dev/null 2>&1 || { echo "[ERROR] No device detected. Enable USB debugging and connect."; exit 1; }

echo "[1/4] Rebooting to fastboot..."
adb reboot bootloader
sleep 5

echo "[2/4] Testing boot image (fastboot boot)..."
fastboot boot kernelsu_patched_boot.img
echo ""
read -p "Did the device boot successfully? (y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Cancelled. Device will reboot normally."
    exit 0
fi

echo "[3/4] Flashing to both slots..."
fastboot flash boot_a kernelsu_patched_boot.img
fastboot flash boot_b kernelsu_patched_boot.img

echo "[4/4] Rebooting..."
fastboot reboot

echo ""
echo "Done!"
echo "Install APK: adb install KernelSU_Next.apk"
