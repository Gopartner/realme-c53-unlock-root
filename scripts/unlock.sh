#!/bin/bash
# Bootloader Unlock Script — Realme C53 (RMX3760)
# Uses CVE-2022-38694 exploit by TomKing062
#
# Prerequisites:
# 1. Install SPRD USB driver
# 2. Download unlock tool from:
#    https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader
# 3. Extract to a folder (e.g., unlock_tool/)
# 4. Phone in SPRD U2S Diag mode (COM3)
#
# WARNING: This WILL wipe your device (factory reset)!

set -e

TOOL_DIR="./unlock_tool"
DEVICE_DIR="rmx3762"  # For RMX3760/RMX3762

echo "=== Realme C53 Bootloader Unlock ==="
echo ""

# Check spd_dump exists
if [ ! -f "$TOOL_DIR/spd_dump.exe" ]; then
    echo "ERROR: spd_dump.exe not found in $TOOL_DIR"
    exit 1
fi

cd "$TOOL_DIR"

echo "[1/7] Dumping bootchain partitions..."
./spd_dump.exe dump 0x00000000 0x00002000 pgpt.bin
./spd_dump.exe dump 0x00002000 0x00006000 splloader.bin
./spd_dump.exe dump 0x0000c000 0x00004000 uboot_a.bin
./spd_dump.exe dump 0x0000e000 0x00002000 misc_a.bin

echo "[2/7] Generating patched SPL..."
./gen_spl-unlock.exe uboot_a.bin

echo "[3/7] Erasing SPL and writing cboot..."
./spd_dump.exe erase 0x00002000 0x00006000
./spd_dump.exe write 0x00002000 $DEVICE_DIR/fdl2-cboot.bin

echo ""
echo "=== SCREWDRIVER STEP ==="
echo "1. Hold BOTH volume keys"
echo "2. Tap power button for 1 second, then release power"
echo "3. Continue holding volume keys"
echo ""
read -p "Press Enter when ready..."

echo "[4/7] Executing unlock payload..."
./spd_dump.exe write 0x00002000 spl-unlock.bin

echo ""
echo "=== SCREWDRIVER STEP (again) ==="
echo "Same procedure: hold both vol keys, tap power"
read -p "Press Enter when ready..."

echo "[5/7] Restoring SPL..."
./spd_dump.exe write 0x00002000 u-boot-spl-16k-sign.bin

echo "[6/7] Restoring uboot..."
./spd_dump.exe write 0x0000c000 uboot_bak.bin

echo "[7/7] Wiping misc partition..."
./spd_dump.exe erase 0x0000e000 0x00002000

echo ""
echo "=== Verification ==="
./spd_dump.exe dump 0x0000e000 0x00000001 miscdata.bin

echo ""
echo "If miscdata.bin is NOT all zeros -> UNLOCKED!"
echo "Phone will now factory reset on next boot."
echo ""
echo "Next steps:"
echo "  - Reboot phone (long press power)"
echo "  - Set up Android (skip most steps)"
echo "  - Enable USB debugging"
echo "  - Run root.sh"
