from datetime import datetime

from .config import BACKUP_DIR, DEVICE_MODEL
from .adb import adb
from .logger import get_logger
from .validation import check_adb_device, validate_device
from .exceptions import DeviceNotDetected

log = get_logger()


def backup_boot():
    print("\n=== Backup Boot Image ===")
    if not validate_device():
        return
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    local_path = BACKUP_DIR / f"stock_boot_{timestamp}.img"
    log.info(f"Backing up boot_a from {DEVICE_MODEL}")
    print("Dumping boot_a...")
    adb('shell "dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.img"')
    print("Pulling boot image...")
    adb(f'pull /data/local/tmp/boot.img "{local_path}"')
    print(f"[OK] Saved: {local_path}")
    log.info(f"Backup saved: {local_path}")
