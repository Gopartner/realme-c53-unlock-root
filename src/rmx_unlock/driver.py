import os

from .config import DRIVER_ZIP
from .exceptions import ReleaseFileMissing
from .logger import get_logger

log = get_logger()


def install_driver():
    print("\n=== Install SPD Driver ===")
    if not DRIVER_ZIP.exists():
        raise ReleaseFileMissing(f"Driver ZIP not found: {DRIVER_ZIP}")
    print(f"Opening: {DRIVER_ZIP.parent}")
    log.info(f"Opening driver folder: {DRIVER_ZIP.parent}")
    os.startfile(DRIVER_ZIP.parent)
    print("\nRun 'DPInst.exe' or 'install.bat' as Administrator.")
