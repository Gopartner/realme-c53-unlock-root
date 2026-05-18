import time
import os

from .config import RUNTIME_IMAGES, RUNTIME_DIR, METADATA_FILE
from .adb import adb, fastboot, reboot_bootloader, wait_for_fastboot, wait_for_device
from .validation import verify_release_file, verify_checksum
from .metadata import get_checksum, parse_metadata, display_metadata
from .exceptions import ReleaseFileMissing, ChecksumMismatch, FlashError
from .logger import get_logger

log = get_logger()


def _verify_image(image_path: str, name: str) -> bool:
    if not verify_release_file(image_path):
        raise ReleaseFileMissing(f"{name} image not found: {image_path}")
    if METADATA_FILE.exists():
        meta = parse_metadata()
        expected = get_checksum(os.path.basename(image_path), meta)
        if expected:
            print(f"Verifying checksum for {name}...")
            verify_checksum(image_path, expected)
            print("[OK] Checksum verified")
    return True


def _flash_both_slots(image_path: str):
    for slot in ["boot_a", "boot_b"]:
        print(f"\nFlashing {slot}...")
        output = fastboot(f'flash {slot} "{image_path}"')
        print(output)
        if "FAILED" in output or "error" in output.lower():
            raise FlashError(f"Failed to flash {slot}: {output}")


def flash_kernelsu():
    print("\n=== Flash KernelSU Boot ===")
    image = str(RUNTIME_IMAGES["kernelsu"])
    _verify_image(image, "KernelSU")
    display_metadata()
    print("\nRebooting to fastboot...")
    reboot_bootloader()
    if not wait_for_fastboot():
        raise FlashError("Device did not enter fastboot mode")
    print("\nTesting boot image (fastboot boot)...")
    test_output = fastboot(f'boot "{image}"')
    print(test_output)
    answer = input("\nDid the device boot successfully? (y/N): ").strip().lower()
    if answer != "y":
        print("[ABORTED] User cancelled after test boot")
        log.info("KernelSU flash aborted after test boot failure")
        return
    print("\nProceeding to flash...")
    _flash_both_slots(image)
    print("\nRebooting...")
    fastboot("reboot")
    print("""
Done.

Install APK:
  adb install tools/apk/KernelSU_Next.apk
""")


def flash_magisk():
    print("\n=== Flash Magisk Boot ===")
    image = str(RUNTIME_IMAGES["magisk"])
    _verify_image(image, "Magisk")
    display_metadata()
    print("\nRebooting to fastboot...")
    reboot_bootloader()
    if not wait_for_fastboot():
        raise FlashError("Device did not enter fastboot mode")
    _flash_both_slots(image)
    print("\nRebooting...")
    fastboot("reboot")
    print("\nDone")


def verify_root():
    print("\n=== Verify Root ===")
    output = adb("shell su -c id")
    if "uid=0" in output:
        print("[OK] ROOT CONFIRMED")
    else:
        print(output)
