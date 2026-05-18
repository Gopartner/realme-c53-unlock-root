import hashlib
import os
import shutil

from .config import DEVICE
from .adb import adb, device_model
from .exceptions import BinaryMissing, UnsupportedDevice, DeviceNotDetected, ChecksumMismatch


def check_binary(name: str) -> bool:
    return shutil.which(name) is not None


def require_binaries(*names: str):
    missing = [n for n in names if not check_binary(n)]
    if missing:
        raise BinaryMissing(f"Required binaries not found: {', '.join(missing)}")


def check_environment():
    print("\n=== Environment Check ===")
    require_binaries("adb", "fastboot")
    for name in ("adb", "fastboot"):
        print(f"[OK] {name}")


def check_adb_device() -> bool:
    output = adb("get-state")
    return "device" in output


def validate_device() -> bool:
    print("\n=== Device Validation ===")
    if not check_adb_device():
        print("[ERROR] Device not detected")
        return False
    model = device_model()
    print(f"Detected: {model}")
    if DEVICE.model not in model:
        print(f"[ERROR] Unsupported device: {model}")
        return False
    print("[OK] Supported device")
    return True


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()


def verify_checksum(path: str, expected: str) -> bool:
    actual = sha256(path)
    if actual != expected:
        raise ChecksumMismatch(
            f"Checksum mismatch for {path}\n"
            f"  Expected: {expected}\n"
            f"  Actual:   {actual}"
        )
    return True


def verify_release_file(path: str) -> bool:
    if not os.path.exists(path):
        print(f"[ERROR] Missing file: {path}")
        return False
    print(f"[OK] {os.path.basename(path)} ({os.path.getsize(path)} bytes)")
    return True
