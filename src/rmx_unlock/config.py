import configparser
import os
import sys
from dataclasses import dataclass, field
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
DEVICES_DIR = REPO_ROOT / "devices"

MAGISK_APK = APK_DIR / "Magisk-v30.7.apk"
KERNELSU_APK = APK_DIR / "KernelSU_Next.apk"
DRIVER_ZIP = DRIVER_DIR / "SPD_Driver_R4.20.4201.zip"

RUNTIME_IMAGES = {
    "magisk": RUNTIME_DIR / "magisk_patched_boot.img",
    "kernelsu": RUNTIME_DIR / "kernelsu_patched_boot.img",
}

METADATA_FILE = RUNTIME_DIR / "metadata.txt"

VERSION = "2.0.0"


@dataclass
class DeviceProfile:
    name: str = "Unknown"
    model: str = "UNKNOWN"
    soc: str = "Unknown"
    chipset: str = ""
    kernel: str = "Unknown"
    android: str = "Unknown"
    build_fingerprint: str = ""
    boot_slots: list = field(default_factory=lambda: ["boot_a", "boot_b"])
    init_boot_slots: list = field(default_factory=list)
    has_super: bool = True
    unlock_method: str = "cve-2022-38694"
    diag_mode: str = "SPRD U2S Diag"
    requires_windows: bool = True
    requires_driver: str = "SPRD"
    kernel_source: str = "https://android.googlesource.com/kernel/common"
    kernel_branch: str = "android14-5.15"
    defconfig: str = "gki_defconfig"
    sublevel: int = 178
    localversion: str = "-android13-8"
    extraversion: str = ""
    is_gki: bool = True
    arch: str = "arm64"


# Current active device profile — updated by set_device()
DEVICE = DeviceProfile()


def list_profiles() -> list:
    if not DEVICES_DIR.exists():
        return []
    return sorted(
        p.stem for p in DEVICES_DIR.iterdir()
        if p.suffix == ".toml" and p.stem != "template"
    )


def load_profile(model: str) -> DeviceProfile:
    path = DEVICES_DIR / f"{model}.toml"
    if not path.exists():
        available = ", ".join(list_profiles()) or "none"
        print(f"[ERROR] Device profile '{model}' not found.")
        print(f"  Available profiles: {available}")
        print(f"  Create a new profile from: devices/template.toml")
        sys.exit(1)

    cfg = configparser.ConfigParser()
    cfg.read(str(path))

    def get(section, key, fallback=""):
        try:
            val = cfg.get(section, key)
            return val.strip('"').strip("'")
        except (configparser.NoSectionError, configparser.NoOptionError):
            return fallback

    def getbool(section, key, fallback=True):
        return get(section, key, str(fallback)).lower() == "true"

    def getint(section, key, fallback=0):
        try:
            return int(get(section, key, str(fallback)))
        except ValueError:
            return fallback

    def getlist(section, key, fallback=None):
        val = get(section, key)
        if val:
            return [v.strip().strip('"').strip("'") for v in val.strip("[]").split(",") if v.strip()]
        return fallback if fallback is not None else []

    return DeviceProfile(
        name=get("device", "name", "Unknown"),
        model=get("device", "model", "UNKNOWN"),
        soc=get("device", "soc", "Unknown"),
        chipset=get("device", "chipset", ""),
        kernel=get("device", "kernel", "Unknown"),
        android=get("device", "android", "Unknown"),
        build_fingerprint=get("device", "build_fingerprint", ""),
        boot_slots=getlist("slots", "boot", ["boot_a", "boot_b"]),
        init_boot_slots=getlist("slots", "init_boot", []),
        has_super=getbool("slots", "super", True),
        unlock_method=get("unlock", "method", "cve-2022-38694"),
        diag_mode=get("unlock", "diag_mode", "SPRD U2S Diag"),
        requires_windows=getbool("unlock", "requires_windows", True),
        requires_driver=get("unlock", "requires_driver", "SPRD"),
        kernel_source=get("build", "kernel_source", "https://android.googlesource.com/kernel/common"),
        kernel_branch=get("build", "kernel_branch", "android14-5.15"),
        defconfig=get("build", "defconfig", "gki_defconfig"),
        sublevel=getint("build", "sublevel", 178),
        localversion=get("build", "localversion", "-android13-8"),
        extraversion=get("build", "extraversion", ""),
        is_gki=getbool("build", "is_gki", True),
        arch=get("build", "arch", "arm64"),
    )


def set_device(model: str = None):
    global DEVICE
    if model is None:
        model = os.environ.get("RMX_DEVICE", "RMX3760")
    loaded = load_profile(model)
    # Mutate in-place so existing references (from `from X import DEVICE`) still see updates
    for key, value in loaded.__dict__.items():
        DEVICE.__dict__[key] = value


# Initialize default device from env var
set_device()
