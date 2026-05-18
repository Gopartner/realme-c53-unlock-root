import os
import subprocess
import sys

from .config import UNLOCK_DIR
from .logger import get_logger

log = get_logger()


def _run(cmd: str, desc: str = ""):
    if desc:
        print(f"\n  [{desc}]")
    log.cmd(cmd)
    result = subprocess.run(cmd, shell=True)
    if result.returncode != 0:
        print(f"  ! Command failed (exit code {result.returncode})")
        if input("  Continue anyway? (y/N): ").lower() != "y":
            sys.exit(1)
    return result


def unlock_bootloader():
    print("\n=== Unlock Bootloader (CVE-2022-38694) ===")
    print(" Prerequisites:")
    print(" - SPRD driver installed (CLI option 4)")
    print(" - Device shows as SPRD U2S Diag (COM3) in Device Manager")
    print(" - Phone OFF, USB cable connected")
    print("")
    input(" Press Enter when ready to start...")

    cwd = os.getcwd()
    os.chdir(str(UNLOCK_DIR))
    log.info(f"Changed to unlock dir: {UNLOCK_DIR}")

    print("\n[1/5] Dumping bootchain partitions...")
    _run("spd_dump.exe dump 0x00000000 0x00002000 pgpt.bin", "Dump PGPT")
    _run("spd_dump.exe dump 0x00002000 0x00006000 splloader.bin", "Dump SPL")
    _run("spd_dump.exe dump 0x0000c000 0x00004000 uboot_a.bin", "Dump UBoot")

    print("\n[2/5] Generating patched SPL...")
    _run("gen_spl-unlock.exe uboot_a.bin", "Generate patched SPL")

    print("\n[3/5] Erasing SPL and writing cboot...")
    _run("spd_dump.exe erase 0x00002000 0x00006000", "Erase SPL")
    _run("spd_dump.exe write 0x00002000 rmx3762/fdl2-cboot.bin", "Write cboot")

    print("")
    print("=== SCREWDRIVER STEP ===")
    print("Hold BOTH volume keys, tap power 1 second, release power.")
    print("Keep holding volume keys.")
    input(" Press Enter when ready...")

    print("\n[4/5] Executing unlock payload...")
    _run("spd_dump.exe write 0x00002000 spl-unlock.bin", "Write unlock payload")

    print("\n[5/5] Restoring bootchain and wiping misc...")
    _run("spd_dump.exe write 0x00002000 u-boot-spl-16k-sign.bin", "Restore SPL")
    _run("spd_dump.exe write 0x0000c000 uboot_bak.bin", "Restore UBoot")
    _run("spd_dump.exe erase 0x0000e000 0x00002000", "Wipe misc")

    print("\n=== Verification ===")
    _run("spd_dump.exe dump 0x0000e000 0x00000001 miscdata.bin", "Read unlock status")
    os.chdir(cwd)

    print("""
 If miscdata.bin has non-zero data -> UNLOCKED!
 Reboot phone (hold power) -> factory reset -> enable USB debugging.
 Then run CLI option 3 to backup boot, option 5 to flash KernelSU.
""")
    log.info("Unlock process completed")
