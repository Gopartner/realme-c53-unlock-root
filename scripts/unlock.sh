#!/bin/bash
# Bootloader Unlock Script — Realme C53 (RMX3760)
# Uses CVE-2022-38694 exploit by TomKing062
#
# Run this script from the repo root directory:
#   ./scripts/unlock.sh
#
# Prerequisites:
# 1. SPRD USB driver installed (tools/driver/)
# 2. Phone in SPRD U2S Diag mode (COM3)
#
# WARNING: This WILL wipe your device (factory reset)!

set -e

TOOL_DIR="./tools/unlock"
DEVICE_DIR="rmx3762"

echo "============================================"
echo " Realme C53 Bootloader Unlock"
echo "============================================"
echo ""

if [ ! -f "$TOOL_DIR/spd_dump.exe" ]; then
    echo "ERROR: spd_dump.exe not found in $TOOL_DIR"
    exit 1
fi

cd "$TOOL_DIR"

echo "[1/5] Dumping bootchain partitions..."
./spd_dump.exe dump 0x00000000 0x00002000 pgpt.bin
./spd_dump.exe dump 0x00002000 0x00006000 splloader.bin
./spd_dump.exe dump 0x0000c000 0x00004000 uboot_a.bin

echo "[2/5] Generating patched SPL..."
./gen_spl-unlock.exe uboot_a.bin

echo "[3/5] Erasing SPL and writing cboot..."
./spd_dump.exe erase 0x00002000 0x00006000
./spd_dump.exe write 0x00002000 $DEVICE_DIR/fdl2-cboot.bin

echo ""
echo "=== SCREWDRIVER STEP 1 ==="
echo "Hold BOTH volume keys, tap power 1 second, release power."
echo "Keep holding volume keys."
echo ""
read -p "Press Enter when ready..."

echo "[4/5] Executing unlock payload..."
./spd_dump.exe write 0x00002000 spl-unlock.bin

echo ""
echo "=== SCREWDRIVER STEP 2 ==="
echo "Same procedure: hold both vol keys, tap power 1 second."
read -p "Press Enter when ready..."

echo "[5/5] Restoring bootchain and wiping misc..."
./spd_dump.exe write 0x00002000 u-boot-spl-16k-sign.bin
./spd_dump.exe write 0x0000c000 uboot_bak.bin
./spd_dump.exe erase 0x0000e000 0x00002000

echo ""
echo "=== Verification ==="
./spd_dump.exe dump 0x0000e000 0x00000001 miscdata.bin

echo ""
echo "If miscdata.bin is NOT all zeros (non-zero data) -> UNLOCKED!"
echo ""
echo "Next steps:"
echo "  - Reboot: hold power button until phone restarts"
echo "  - Phone will factory reset (normal after unlock)"
echo "  - Set up Android, enable USB debugging"
echo "  - Run: ./scripts/root_magisk.sh"
