import os
import subprocess
import sys

from .config import DEVICE, UNLOCK_BASE
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


def _chipset_dir() -> str:
    family = DEVICE.chipset_family
    d = UNLOCK_BASE / family
    if not d.exists():
        d.mkdir(parents=True, exist_ok=True)
    return str(d)


def _sprd_unlock():
    print(f"\n=== SPRD Unlock (CVE-2022-38694) — {DEVICE.model} ===")
    print(f" Device: {DEVICE.name}")
    print(f" Diag mode: {DEVICE.diag_mode}")
    if DEVICE.download_mode_instructions:
        print(f" Enter download mode: {DEVICE.download_mode_instructions}")
    print("")
    input(" Press Enter when ready to start...")

    cwd = os.getcwd()
    workdir = _chipset_dir()
    os.chdir(workdir)
    log.info(f"Changed to unlock dir: {workdir}")

    print("\n[1/5] Dumping bootchain partitions...")
    _run("spd_dump.exe dump 0x00000000 0x00002000 pgpt.bin", "Dump PGPT")
    _run("spd_dump.exe dump 0x00002000 0x00006000 splloader.bin", "Dump SPL")
    _run("spd_dump.exe dump 0x0000c000 0x00004000 uboot_a.bin", "Dump UBoot")

    print("\n[2/5] Generating patched SPL...")
    _run("gen_spl-unlock.exe uboot_a.bin", "Generate patched SPL")

    print("\n[3/5] Erasing SPL and writing cboot...")
    _run("spd_dump.exe erase 0x00002000 0x00006000", "Erase SPL")
    _run(f"spd_dump.exe write 0x00002000 {DEVICE.model.lower()}/fdl2-cboot.bin", "Write cboot")

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
 Then run CLI option 3 to backup boot, option 6 to flash.
""")


def _mtk_unlock():
    print(f"\n=== MediaTek BROM Unlock — {DEVICE.model} ===")
    print(f" Device: {DEVICE.name}")
    print(f" Chipset: {DEVICE.chipset} ({DEVICE.chipset_family})")
    if DEVICE.download_mode_instructions:
        print(f" Enter BROM mode: {DEVICE.download_mode_instructions}")
    print(f"")
    print(f" Required tools in tools/unlock/mtk/:")
    print(f"   - mtkclient (mtk, mtk_gui)")
    print(f"   - OR brom_mode.exe + SP Flash Tool")
    print(f"")
    print(f" Install mtkclient: pip install mtkclient")
    print(f" Or download from: https://github.com/bkerler/mtkclient")
    print(f"")
    input(" Press Enter when ready...")

    workdir = _chipset_dir()
    mtk_bin = os.path.join(workdir, "mtk")
    if os.path.exists(mtk_bin) or subprocess.run("where mtk", shell=True, capture_output=True).returncode == 0:
        print("\n Using mtkclient...")
        _run(f"mtk da seccfg unlock", "BROM unlock via mtkclient")
    else:
        print("\n[!] mtkclient not found.")
        print(" Place mtkclient.exe or brom_mode.exe in tools/unlock/mtk/")
        print(" Or install: pip install mtkclient")
        print("")
        print(" Alternative manual steps:")
        print(" 1. Connect device in BROM mode")
        print(" 2. Use SP Flash Tool to dump preloader + boot")
        print(" 3. Patch with appropriate unlock tool")
        print(" 4. Flash back")
        if input(" Open browser to mtkclient GitHub? (y/N): ").lower() == "y":
            import webbrowser
            webbrowser.open("https://github.com/bkerler/mtkclient")


def _qcom_unlock():
    print(f"\n=== Qualcomm Unlock — {DEVICE.model} ===")
    print(f" Device: {DEVICE.name}")
    print(f" Chipset: {DEVICE.chipset}")
    print(f" Method: {DEVICE.unlock_method}")
    print(f"")

    if DEVICE.unlock_method == "fastboot-oem":
        print(" Using fastboot OEM unlock...")
        print(" Bootloader must already allow: fastboot flashing unlock")
        print("")
        input(" Press Enter to attempt unlock...")
        _run("fastboot flashing unlock", "fastboot flashing unlock")
        _run("fastboot flashing get_unlock_ability", "Check unlock ability")
        print("""
 If the device shows a confirmation prompt on screen:
   Use volume keys to select UNLOCK, press power.
 Then reboot: fastboot reboot
""")
    else:
        print(f"\n EDL mode unlock for {DEVICE.chipset}")
        print(" Required tools in tools/unlock/qcom/:")
        print("   - QFIL / QPST (Windows)")
        print("   - edl (Python): pip install edl")
        print("   - Firehose programmer file (device-specific)")
        print("")
        print(" Manual steps:")
        print(" 1. Enter EDL mode (test point or vol keys)")
        print(" 2. Use QFIL to flash patched boot image")
        print(" 3. Or use: edl --loader=prog_ufs_firehose_*.elf unlock")
        print("")
        if input(" Open browser to edl tool? (y/N): ").lower() == "y":
            import webbrowser
            webbrowser.open("https://github.com/bkerler/edl")


def _unlock_not_supported():
    print(f"\n=== Unlock — {DEVICE.model} ===")
    print(f" Method '{DEVICE.unlock_method}' for {DEVICE.chipset_family} is not yet implemented.")
    print(f" Device: {DEVICE.name} ({DEVICE.model})")
    print(f" Chipset: {DEVICE.soc} ({DEVICE.chipset})")
    print(f"")
    print(f" You can contribute by adding the unlock flow for this chipset.")
    print(f" Edit: src/rmx_unlock/unlock.py")
    print(f" Reference: https://github.com/bkerler/mtkclient (MTK)")
    print(f" Reference: https://github.com/bkerler/edl (Qualcomm)")
    print(f"")
    print(f" Meanwhile, you can still use menu options:")
    print(f"   1) Check environment")
    print(f"   2) Validate device")
    print(f"   3) Backup stock boot image")
    print(f"   8) Verify root")


def unlock_bootloader():
    print(f"\n=== Bootloader Unlock — {DEVICE.name} ({DEVICE.model}) ===")
    print(f" Chipset: {DEVICE.chipset_family} | Method: {DEVICE.unlock_method}")
    print(f"")

    method_map = {
        "sprd": _sprd_unlock,
        ("sprd", "cve-2022-38694"): _sprd_unlock,
        "mediatek": _mtk_unlock,
        ("mediatek", "mtk-brom"): _mtk_unlock,
        "qualcomm": _qcom_unlock,
        ("qualcomm", "fastboot-oem"): _qcom_unlock,
        ("qualcomm", "qcom-edl"): _qcom_unlock,
    }

    key = (DEVICE.chipset_family, DEVICE.unlock_method)
    handler = method_map.get(key) or method_map.get(DEVICE.chipset_family)

    if handler:
        handler()
    else:
        _unlock_not_supported()

    log.info(f"Unlock process completed for {DEVICE.model}")
