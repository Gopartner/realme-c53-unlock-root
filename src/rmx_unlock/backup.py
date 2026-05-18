from datetime import datetime

from .config import BACKUP_DIR, DEVICE


def backup_boot():
    slot = DEVICE.boot_slots[0]
    log.info(f"Backing up {slot} from {DEVICE.model}")
    print(f"Dumping {slot}...")
    adb(f'shell "dd if=/dev/block/by-name/{slot} of=/data/local/tmp/boot.img"')
    print("Pulling boot image...")
    adb(f'pull /data/local/tmp/boot.img "{local_path}"')
    print(f"[OK] Saved: {local_path}")
    log.info(f"Backup saved: {local_path}")
