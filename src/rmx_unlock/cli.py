from .config import DEVICE, DEVICES_DIR, set_device, list_profiles
from .validation import check_environment, validate_device
from .backup import backup_boot
from .driver import install_driver
from .flash import flash_kernelsu, flash_magisk, verify_root
from .unlock import unlock_bootloader
from .metadata import display_metadata, parse_metadata
from .logger import get_logger
import os

log = get_logger()


def menu() -> str:
    title = f"{DEVICE.name} Unlock & Root Toolkit v2.0.0"
    subtitle = f"{DEVICE.model} | {DEVICE.soc} | {DEVICE.chipset_family}"
    padding = max(0, 46 - len(title))
    padding2 = max(0, 46 - len(subtitle))
    method_label = {
        "cve-2022-38694": " (CVE-2022-38694)",
        "mtk-brom": " (BROM mode)",
        "qcom-edl": " (EDL mode)",
        "fastboot-oem": " (fastboot oem)",
    }.get(DEVICE.unlock_method, "")
    print(f"""
+------------------------------------------------+
| {title}{' ' * padding} |
+------------------------------------------------+
| {subtitle}{' ' * padding2} |
+------------------------------------------------+

  1) Check environment
  2) Validate device
  3) Backup stock boot image
  4) Install {DEVICE.requires_driver} driver
  5) Unlock bootloader{method_label}
  6) Flash KernelSU (with test-boot)
  7) Flash Magisk
  8) Verify root access
  9) Show release metadata
  d) Switch device profile

   q) Quit

  Tip: Start with 1 -> 2 -> 4 -> 5 -> 3 -> 6 for full flow.
""")
    return input("Select: ").strip()


def select_device():
    profiles = list_profiles()
    if not profiles:
        print("[ERROR] No device profiles found in devices/")
        return
    print(f"\nCurrent device: {DEVICE.name} ({DEVICE.model})")
    print("\nAvailable profiles:")
    for i, p in enumerate(profiles, 1):
        print(f"  {i}) {p}")
    print(f"  q) Cancel")
    choice = input("\nSelect profile: ").strip()
    if choice.lower() == "q":
        return
    try:
        idx = int(choice) - 1
        if 0 <= idx < len(profiles):
            set_device(profiles[idx])
            print(f"[OK] Switched to {DEVICE.name} ({DEVICE.model})")
        else:
            print("[ERROR] Invalid selection")
    except ValueError:
        print("[ERROR] Invalid input")


def main():
    log.info("=== RMX Unlock Tool started ===")
    # Check RMX_DEVICE env var for profile override
    env_dev = os.environ.get("RMX_DEVICE")
    if env_dev and env_dev != DEVICE.model:
        set_device(env_dev)
        log.info(f"Device set from env: {DEVICE.model}")
    while True:
        try:
            choice = menu()
            if choice == "1":
                check_environment()
            elif choice == "2":
                validate_device()
            elif choice == "3":
                backup_boot()
            elif choice == "4":
                install_driver()
            elif choice == "5":
                unlock_bootloader()
            elif choice == "6":
                flash_kernelsu()
            elif choice == "7":
                flash_magisk()
            elif choice == "8":
                verify_root()
            elif choice == "9":
                try:
                    display_metadata(parse_metadata())
                except Exception as e:
                    print(f"[ERROR] {e}")
            elif choice.lower() == "d":
                select_device()
            elif choice.lower() == "q":
                break
            else:
                print("Invalid option")
            if choice.lower() != "q":
                input("\nPress Enter to continue...")
        except KeyboardInterrupt:
            print("\n\nExiting...")
            break
        except Exception as e:
            print(f"\n[ERROR] {e}")
            log.error(f"Unhandled error: {e}")
            input("\nPress Enter to continue...")
    log.info("=== RMX Unlock Tool exited ===")


if __name__ == "__main__":
    main()
