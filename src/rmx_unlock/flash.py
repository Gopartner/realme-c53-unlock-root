import os

from .config import RUNTIME_IMAGE, METADATA_FILE
from .adb import adb, fastboot, reboot_bootloader, wait_for_fastboot
from .validation import verify_release_file, verify_checksum
from .metadata import get_checksum, parse_metadata, display_metadata
from .exceptions import ReleaseFileMissing, FlashError
from .logger import get_logger

log = get_logger()


def _verify_image(image_path: str):
    if not verify_release_file(image_path):
        raise ReleaseFileMissing(f"Image not found: {image_path}")
    if METADATA_FILE.exists():
        meta = parse_metadata()
        expected = get_checksum(os.path.basename(image_path), meta)
        if expected:
            print("Verifying checksum...")
            verify_checksum(image_path, expected)
            print("[OK] Checksum verified")


def _flash_both_slots(image_path: str):
    for slot in ["boot_a", "boot_b"]:
        print(f"\nFlashing {slot}...")
        output = fastboot(f'flash {slot} "{image_path}"')
        print(output)
        if "FAILED" in output or "error" in output.lower():
            raise FlashError(f"Failed to flash {slot}: {output}")


def flash_kernelsu():
    print("\n=== Flash KernelSU Boot ===")
    image = str(RUNTIME_IMAGE)
    _verify_image(image)
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


def verify_root():
    print("\n=== Verify Root ===")
    output = adb("shell su -c id")
    if "uid=0" in output:
        print("[OK] ROOT CONFIRMED")
    else:
        print(output)
