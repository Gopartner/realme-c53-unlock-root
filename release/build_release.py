#!/usr/bin/env python3
"""
Build Release Pipeline
======================
Run by the developer (or CI) to produce safe release artifacts.

No live patching on user devices — all patching happens here.
Output goes to release/runtime/ with checksums in metadata.txt.

Usage:
    python release/build_release.py --magisk path/to/Magisk-v30.7.apk
    python release/build_release.py --kernelsu path/to/kernelsu.ko --stock path/to/stock_boot.img
"""

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Optional

REPO_ROOT = Path(__file__).resolve().parents[1]
TOOLS = REPO_ROOT / "tools"
APK_DIR = TOOLS / "apk"
RUNTIME_DIR = REPO_ROOT / "release" / "runtime"
OUTPUT_DIR = REPO_ROOT / "output"
BACKUP_DIR = OUTPUT_DIR / "backup"

MAGISK_APK = APK_DIR / "Magisk-v30.7.apk"

MSYS2_ENV = {**os.environ.copy(), "MSYS2_ARG_CONV_EXCL": "*"}


def log(message: str):
    print(f"[BUILD] {message}")


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()


def adb(cmd: str) -> str:
    result = subprocess.run(
        f"adb {cmd}", shell=True, text=True, capture_output=True, env=MSYS2_ENV
    )
    return (result.stdout + result.stderr).strip()


def run(cmd: str, shell: bool = True, check: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, shell=shell, check=check, text=True)


def find_stock_boot() -> Optional[Path]:
    candidates = [
        REPO_ROOT / "stock_boot.img",
        BACKUP_DIR / "stock_boot.img",
    ]
    if BACKUP_DIR.exists():
        boots = sorted(BACKUP_DIR.glob("stock_boot_*.img"))
        if boots:
            candidates.extend(reversed(boots))
    for c in candidates:
        if c.exists():
            return c
    return None


def extract_magisk(apk_path: str, dest: str):
    log("Extracting Magisk binaries...")
    import zipfile
    with zipfile.ZipFile(apk_path, "r") as z:
        members = [
            "assets/boot_patch.sh",
            "assets/util_functions.sh",
            "lib/arm64-v8a/libmagiskboot.so",
            "lib/arm64-v8a/libmagiskinit.so",
            "lib/arm64-v8a/libmagisk.so",
            "lib/arm64-v8a/libmagiskpolicy.so",
            "lib/arm64-v8a/libbusybox.so",
            "lib/arm64-v8a/libinit-ld.so",
        ]
        for member in members:
            try:
                z.extract(member, dest)
            except KeyError:
                log(f"  [WARN] {member} not found in APK")
    # Rename .so files
    so_dir = Path(dest) / "lib" / "arm64-v8a"
    if so_dir.exists():
        rename_map = {
            "libmagiskboot.so": "magiskboot",
            "libmagiskinit.so": "magiskinit",
            "libmagisk.so": "magisk",
            "libmagiskpolicy.so": "magiskpolicy",
            "libbusybox.so": "busybox",
            "libinit-ld.so": "init-ld",
        }
        for old, new in rename_map.items():
            src = so_dir / old
            if src.exists():
                dest_file = Path(dest) / "assets" / new if new == "magiskboot" else Path(dest) / new
                shutil.copy2(src, dest_file)
                os.chmod(dest_file, 0o755)
        shutil.rmtree(str(so_dir))


def push_and_patch(stock_path: str, magisk_dir: str, output_name: str) -> str:
    tmp = "/data/local/tmp/build_magisk"
    adb(f"shell rm -rf {tmp}")
    adb(f"shell mkdir -p {tmp}/magisk")
    log("Pushing stock boot to device...")
    adb(f'push "{stock_path}" {tmp}/boot.img')
    log("Pushing Magisk binaries...")
    for f in os.listdir(magisk_dir):
        fp = os.path.join(magisk_dir, f)
        if os.path.isfile(fp):
            adb(f'push "{fp}" {tmp}/magisk/{f}')
    assets_dir = os.path.join(magisk_dir, "assets")
    if os.path.isdir(assets_dir):
        for f in os.listdir(assets_dir):
            fp = os.path.join(assets_dir, f)
            if os.path.isfile(fp):
                adb(f'push "{fp}" {tmp}/magisk/{f}')
    adb(f"shell chmod 755 {tmp}/magisk/*")
    log("Patching boot image...")
    adb(f"shell sh {tmp}/magisk/boot_patch.sh {tmp}/boot.img")
    output_path = os.path.join(RUNTIME_DIR, output_name)
    adb(f'pull {tmp}/magisk/new-boot.img "{output_path}"')
    adb(f"shell rm -rf {tmp}")
    return output_path


def build_magisk(stock_path: str):
    log("=== Building Magisk-patched boot image ===")
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmpdir:
        extract_magisk(str(MAGISK_APK), tmpdir)
        output = push_and_patch(stock_path, tmpdir, "magisk_patched_boot.img")
    log(f"[OK] Magisk image: {output}")
    return output


def build_kernelsu(stock_path: str, kernelsu_ko_path: str):
    log("=== Building KernelSU-patched boot image ===")
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    output = os.path.join(RUNTIME_DIR, "kernelsu_patched_boot.img")
    tmp = "/data/local/tmp/build_ksu"
    adb(f"shell rm -rf {tmp}")
    adb(f"shell mkdir -p {tmp}")
    log("Pushing stock boot and kernel module...")
    adb(f'push "{stock_path}" {tmp}/boot.img')
    adb(f'push "{kernelsu_ko_path}" {tmp}/kernelsu.ko')
    log("Pushing magiskboot for repack...")
    with tempfile.TemporaryDirectory() as tmpdir:
        extract_magisk(str(MAGISK_APK), tmpdir)
        magiskboot = os.path.join(tmpdir, "assets", "magiskboot")
        if not os.path.exists(magiskboot):
            magiskboot = os.path.join(tmpdir, "lib", "arm64-v8a", "libmagiskboot.so")
        if os.path.exists(magiskboot):
            adb(f'push "{magiskboot}" {tmp}/magiskboot')
            adb(f"shell chmod 755 {tmp}/magiskboot")
    log("Patching with ksud (KernelSU boot-patch)...")
    ksud = shutil.which("ksud")
    if ksud:
        adb(f'push "{ksud}" {tmp}/ksud')
        adb(f"shell chmod 755 {tmp}/ksud")
        adb(f"shell {tmp}/ksud boot-patch "
            f"-b {tmp}/boot.img "
            f"-m {tmp}/kernelsu.ko "
            f"--magiskboot {tmp}/magiskboot "
            f"-o {tmp}/ "
            f"--out-name kernelsu_patched_boot.img")
    else:
        log("[WARN] ksud not found in PATH, trying to use magiskboot directly")
        adb(f"shell {tmp}/magiskboot unpack {tmp}/boot.img")
        adb(f"shell cp {tmp}/kernelsu.ko {tmp}/kernel")
        adb(f"shell {tmp}/magiskboot repack {tmp}/boot.img {tmp}/kernelsu_patched_boot.img")
    adb(f'pull {tmp}/kernelsu_patched_boot.img "{output}"')
    adb(f"shell rm -rf {tmp}")
    log(f"[OK] KernelSU image: {output}")
    return output


def write_metadata(artifacts: dict):
    meta_path = RUNTIME_DIR / "metadata.txt"
    lines = [
        "# Realme C53 (RMX3760) Release Metadata",
        f"# Generated: {datetime.now().isoformat()}",
        f"# Tool Version: 2.0.0",
        f"DEVICE=RMX3760",
        f"SOC=Unisoc T612 (ums9230)",
        f"KERNEL=5.15.178-android13-8",
        f"ANDROID=15 (AP3A.240905.015.A2)",
        "",
    ]
    for name, path in artifacts.items():
        if os.path.exists(path):
            chksum = sha256(path)
            size = os.path.getsize(path)
            lines.append(f"SHA256_{name}={chksum}")
            lines.append(f"SIZE_{name}={size}")
    with open(meta_path, "w") as f:
        f.write("\n".join(lines) + "\n")
    log(f"[OK] Metadata: {meta_path}")


def build_all():
    stock = find_stock_boot()
    if not stock:
        log("[ERROR] No stock boot image found. Run backup first or provide --stock.")
        sys.exit(1)
    log(f"Using stock boot: {stock}")
    images = {}
    if MAGISK_APK.exists():
        images["magisk_patched_boot.img"] = build_magisk(str(stock))
    else:
        log(f"[SKIP] Magisk APK not found: {MAGISK_APK}")
    kernelsu_ko = REPO_ROOT / "kernelsu.ko"
    if kernelsu_ko.exists():
        images["kernelsu_patched_boot.img"] = build_kernelsu(str(stock), str(kernelsu_ko))
    else:
        log(f"[SKIP] kernelsu.ko not found: {kernelsu_ko}")
    if images:
        write_metadata(images)
        log("Build complete. Artifacts in release/runtime/")
    else:
        log("[ERROR] Nothing to build")
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build release artifacts for RMX3760")
    parser.add_argument("--magisk", help="Path to Magisk APK")
    parser.add_argument("--kernelsu", help="Path to kernelsu.ko")
    parser.add_argument("--stock", help="Path to stock boot image")
    parser.add_argument("--all", action="store_true", help="Build everything available")
    args = parser.parse_args()
    if args.all or not any([args.magisk, args.kernelsu]):
        build_all()
    else:
        stock = args.stock or find_stock_boot()
        if not stock:
            log("[ERROR] No stock boot image. Use --stock.")
            sys.exit(1)
        images = {}
        if args.magisk:
            images["magisk_patched_boot.img"] = build_magisk(str(stock))
        if args.kernelsu:
            images["kernelsu_patched_boot.img"] = build_kernelsu(str(stock), args.kernelsu)
        if images:
            write_metadata(images)
