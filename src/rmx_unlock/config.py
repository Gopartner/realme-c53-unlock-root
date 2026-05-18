from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
TOOLS = REPO_ROOT / "tools"
APK_DIR = TOOLS / "apk"
UNLOCK_DIR = TOOLS / "unlock"
DRIVER_DIR = TOOLS / "driver"
RELEASE_DIR = REPO_ROOT / "release"
RUNTIME_DIR = RELEASE_DIR / "runtime"
BUILD_DIR = RELEASE_DIR / "build"
OUTPUT_DIR = REPO_ROOT / "output"
BACKUP_DIR = OUTPUT_DIR / "backup"
LOG_DIR = OUTPUT_DIR / "logs"
SRC_DIR = REPO_ROOT / "src"

DEVICE_MODEL = "RMX3760"
DEVICE_SOC = "Unisoc T612 (ums9230)"
DEVICE_KERNEL = "5.15.178-android13-8"
DEVICE_ANDROID = "15 (AP3A.240905.015.A2)"
DEVICE_SLOTS = ["boot_a", "boot_b"]

MAGISK_APK = APK_DIR / "Magisk-v30.7.apk"
KERNELSU_APK = APK_DIR / "KernelSU_Next.apk"
DRIVER_ZIP = DRIVER_DIR / "SPD_Driver_R4.20.4201.zip"

RUNTIME_IMAGES = {
    "magisk": RUNTIME_DIR / "magisk_patched_boot.img",
    "kernelsu": RUNTIME_DIR / "kernelsu_patched_boot.img",
}

METADATA_FILE = RUNTIME_DIR / "metadata.txt"

VERSION = "2.0.0"
