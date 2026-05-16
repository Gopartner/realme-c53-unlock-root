#!/usr/bin/env python3
# Realme C53 (RMX3760) — Bootloader Unlock & Root CLI Tool

import os
import sys
import subprocess
import shutil
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent
TOOLS = REPO_ROOT / "tools"
UNLOCK = TOOLS / "unlock"
APK = TOOLS / "apk"
SPRD_ZIP = TOOLS / "driver" / "SPD_Driver_R4.20.4201.zip"


def run(cmd, desc=None, shell=False):
    if desc:
        print(f"\n  [{desc}]")
    result = subprocess.run(cmd, shell=shell)
    if result.returncode != 0:
        print(f"  ! Command failed (exit code {result.returncode})")
        if input("  Continue anyway? (y/N): ").lower() != "y":
            sys.exit(1)
    return result


def adb(cmd, desc=None):
    env = os.environ.copy()
    env["MSYS2_ARG_CONV_EXCL"] = "*"
    full_cmd = f"adb {cmd}"
    if desc:
        print(f"\n  [{desc}]")
    result = subprocess.run(full_cmd, shell=True, env=env)
    if result.returncode != 0:
        print(f"  ! ADB command failed")
        if input("  Continue? (y/N): ").lower() != "y":
            sys.exit(1)
    return result


def fastboot(cmd, desc=None):
    if desc:
        print(f"\n  [{desc}]")
    result = subprocess.run(f"fastboot {cmd}", shell=True)
    if result.returncode != 0:
        print(f"  ! Fastboot command failed")
        if input("  Continue? (y/N): ").lower() != "y":
            sys.exit(1)
    return result


def check_adb():
    result = subprocess.run("adb get-state", shell=True, capture_output=True, text=True)
    return "device" in result.stdout or "device" in result.stderr


def menu():
    print("""
+----------------------------------------+
|  Realme C53 (RMX3760) Unlock & Root    |
+----------------------------------------+
""")
    print("1) Backup data from phone")
    print("2) Install SPRD driver (open folder)")
    print("3) Unlock bootloader")
    print("4) Dump stock boot image")
    print("5) Root with Magisk")
    print("6) Verify root access")
    print("q) Quit")
    return input("\nSelect: ").strip()


def cmd_backup():
    print("\n=== Backup Data ===")
    print(" WARNING: Unlocking wipes the device.")
    if not check_adb():
        print(" ! Phone not detected. Connect via USB with debugging enabled.")
        return
    backup_dir = REPO_ROOT / f"backup_{__import__('datetime').datetime.now().strftime('%Y%m%d_%H%M%S')}"
    backup_dir.mkdir(parents=True, exist_ok=True)

    print("\n Copying media files...")
    adb("shell mkdir -p /sdcard/backup")
    for folder in ["DCIM", "Pictures", "Download", "Movies", "Music", "Documents"]:
        adb(f'shell cp -r /sdcard/{folder} /sdcard/backup/ 2>/dev/null || true')
    adb(f'pull /sdcard/backup/ "{backup_dir}"')

    print("\n Dumping stock boot image...")
    adb('shell "dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.bin 2>/dev/null"')
    adb(f'pull /data/local/tmp/boot.bin "{backup_dir / "stock_boot.img"}"')

    shutil.copy2(backup_dir / "stock_boot.img", REPO_ROOT / "stock_boot.img")
    print(f"\n Done! Files saved to: {backup_dir}")
    print(" Stock boot image copied to repo root.")


def cmd_driver():
    print("\n=== Install SPRD Driver ===")
    driver_dir = REPO_ROOT / "tools" / "driver" / "SPD_Driver_R4.20.4201"
    if not driver_dir.exists():
        print(" Extracting driver...")
        with zipfile.ZipFile(SPRD_ZIP, "r") as z:
            z.extractall(driver_dir)
    print(f" Open: {driver_dir}")
    print(" Run 'DPInst.exe' or 'install.bat' as Administrator.")
    os.startfile(driver_dir)


def cmd_unlock():
    print("\n=== Unlock Bootloader ===")
    print(" Prerequisites:")
    print(" - SPRD driver installed")
    print(" - Phone OFF")
    print(" - USB cable connected")
    print("")
    input(" Press Enter when ready to start...")

    cwd = os.getcwd()
    os.chdir(UNLOCK)

    print("\n[1/5] Dumping bootchain partitions...")
    run("spd_dump.exe dump 0x00000000 0x00002000 pgpt.bin", "Dump PGPT")
    run("spd_dump.exe dump 0x00002000 0x00006000 splloader.bin", "Dump SPL")
    run("spd_dump.exe dump 0x0000c000 0x00004000 uboot_a.bin", "Dump UBoot")

    print("\n[2/5] Generating patched SPL...")
    run("gen_spl-unlock.exe uboot_a.bin", "Generate patched SPL")

    print("\n[3/5] Erasing SPL and writing cboot...")
    run("spd_dump.exe erase 0x00002000 0x00006000", "Erase SPL")
    run("spd_dump.exe write 0x00002000 rmx3762/fdl2-cboot.bin", "Write cboot")

    print("")
    print("=== SCREWDRIVER STEP ===")
    print("Hold BOTH volume keys, tap power 1 second, release power.")
    print("Keep holding volume keys.")
    input(" Press Enter when ready...")

    print("\n[4/5] Executing unlock payload...")
    run("spd_dump.exe write 0x00002000 spl-unlock.bin", "Write unlock payload")

    print("\n[5/5] Restoring bootchain and wiping misc...")
    run("spd_dump.exe write 0x00002000 u-boot-spl-16k-sign.bin", "Restore SPL")
    run("spd_dump.exe write 0x0000c000 uboot_bak.bin", "Restore UBoot")
    run("spd_dump.exe erase 0x0000e000 0x00002000", "Wipe misc")

    print("\n=== Verification ===")
    run("spd_dump.exe dump 0x0000e000 0x00000001 miscdata.bin", "Read unlock status")
    os.chdir(cwd)

    print("""
 If miscdata.bin has non-zero data -> UNLOCKED!
 Reboot phone (hold power) -> factory reset -> enable USB debugging.
 Then run option 4 and 5.
""")


def cmd_dump_boot():
    print("\n=== Dump Stock Boot Image ===")
    if not check_adb():
        print(" ! Phone not detected.")
        return
    adb('shell "dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.bin 2>/dev/null"', "Dump boot_a")
    adb('pull /data/local/tmp/boot.bin "stock_boot.img"', "Pull to PC")
    stock_path = REPO_ROOT / "stock_boot.img"
    boot_path = REPO_ROOT / "boot.bin"
    if boot_path.exists():
        boot_path.rename(stock_path)
    print(" Saved: stock_boot.img")
    print(" Ready for Magisk patching.")


def cmd_root():
    print("\n=== Root with Magisk ===")

    magisk_apk = APK / "Magisk-v30.7.apk"
    stock_boot = REPO_ROOT / "stock_boot.img"

    if not magisk_apk.exists():
        print(f" ! Magisk APK not found: {magisk_apk}")
        return
    if not stock_boot.exists():
        print(f" ! stock_boot.img not found. Run option 4 first.")
        return
    if not check_adb():
        print(" ! Phone not detected.")
        return

    print("\n[1/5] Installing Magisk app...")
    adb(f'install "{magisk_apk}"', "Install APK")

    print("\n[2/5] Extracting Magisk binaries...")
    magisk_dir = REPO_ROOT / "magisk_files"
    if magisk_dir.exists():
        shutil.rmtree(magisk_dir)
    with zipfile.ZipFile(magisk_apk, "r") as z:
        z.extractall(magisk_dir)

    print("\n[3/5] Pushing files to phone...")
    adb("shell mkdir -p /data/local/tmp/magisk")
    files_map = {
        "assets/boot_patch.sh": "boot_patch.sh",
        "assets/util_functions.sh": "util_functions.sh",
        "assets/addon.d.sh": "addon.d.sh",
        "assets/module_installer.sh": "module_installer.sh",
        "assets/stub.apk": "stub.apk",
        "lib/arm64-v8a/libmagiskboot.so": "magiskboot",
        "lib/arm64-v8a/libmagiskinit.so": "magiskinit",
        "lib/arm64-v8a/libmagisk.so": "magisk",
        "lib/arm64-v8a/libmagiskpolicy.so": "magiskpolicy",
        "lib/arm64-v8a/libbusybox.so": "busybox",
        "lib/arm64-v8a/libinit-ld.so": "init-ld",
    }
    for src, dst in files_map.items():
        src_path = magisk_dir / src
        if src_path.exists():
            adb(f'push "{src_path}" /data/local/tmp/magisk/{dst}')
    adb("shell chmod 755 /data/local/tmp/magisk/*")

    print("\n[4/5] Patching boot image...")
    env = os.environ.copy()
    env["MSYS2_ARG_CONV_EXCL"] = "*"
    subprocess.run(f'adb push "{stock_boot}" /data/local/tmp/boot.img', shell=True, env=env)
    subprocess.run("adb shell /data/local/tmp/magisk/boot_patch.sh /data/local/tmp/boot.img",
                   shell=True, env=env)
    subprocess.run(f'adb pull /data/local/tmp/magisk/new-boot.img "{REPO_ROOT / "magisk_patched_boot.img"}"',
                   shell=True, env=env)

    print("\n[5/5] Flashing patched boot...")
    patched = REPO_ROOT / "magisk_patched_boot.img"
    if not patched.exists():
        print(" ! Patched boot image not found!")
        return

    adb("reboot bootloader", "Reboot to fastboot")
    __import__("time").sleep(3)
    fastboot(f'flash boot_a "{patched}"', "Flash boot_a")
    fastboot(f'flash boot_b "{patched}"', "Flash boot_b")
    fastboot("reboot", "Reboot")

    print("""
 Done! After phone reboots:
   Open Magisk app -> Superuser -> Grant root to Shell.

 Verify: adb shell su -c id  ->  uid=0(root)
""")


def cmd_verify():
    print("\n=== Verify Root Access ===")
    if not check_adb():
        print(" ! Phone not detected.")
        return
    result = subprocess.run('adb shell su -c id', shell=True, capture_output=True, text=True)
    output = result.stdout + result.stderr
    if "uid=0" in output:
        print(" ROOT CONFIRMED: uid=0(root)")
    elif "su: inaccessible" in output:
        print(" Not rooted. Open Magisk app and grant root to Shell.")
    else:
        print(f" Response: {output.strip()}")


def main():
    while True:
        choice = menu()
        if choice == "1":
            cmd_backup()
        elif choice == "2":
            cmd_driver()
        elif choice == "3":
            cmd_unlock()
        elif choice == "4":
            cmd_dump_boot()
        elif choice == "5":
            cmd_root()
        elif choice == "6":
            cmd_verify()
        elif choice.lower() == "q":
            print("bye.")
            break
        else:
            print(" Invalid option.")
        if choice not in ("q", "Q"):
            input("\nPress Enter to continue...")


if __name__ == "__main__":
    main()
