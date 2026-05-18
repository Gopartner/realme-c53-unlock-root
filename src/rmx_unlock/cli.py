from .validation import check_environment, validate_device
from .backup import backup_boot
from .driver import install_driver
from .flash import flash_kernelsu, flash_magisk, verify_root
from .unlock import unlock_bootloader
from .metadata import display_metadata, parse_metadata
from .logger import get_logger

log = get_logger()


def menu() -> str:
    print("""
+------------------------------------------------+
| Realme C53 Unlock & Root Toolkit  v2.0.0       |
+------------------------------------------------+
| RMX3760 | Unisoc T612                          |
+------------------------------------------------+

  1) Check environment
  2) Validate device
  3) Backup stock boot image
  4) Install SPD driver
  5) Unlock bootloader (CVE-2022-38694)
  6) Flash KernelSU (with test-boot)
  7) Flash Magisk
  8) Verify root access
  9) Show release metadata

  q) Quit
""")
    return input("Select: ").strip()


def main():
    log.info("=== RMX Unlock Tool started ===")
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
