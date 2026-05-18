#!/usr/bin/env python3
"""
Build Release Pipeline
======================
Run by the developer (or CI) to produce safe release artifacts.

No live patching on user devices — all patching happens here.
Output goes to release/runtime/ with checksums in metadata.txt.

Usage:
    python release/build_release.py --magisk tools/apk/Magisk-v30.7.apk --stock ...
    python release/build_release.py --kernelsu kernelsu.ko --stock ...
    python release/build_release.py --all
"""

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Optional

REPO_ROOT = Path(__file__).resolve().parents[1]
RUNTIME_DIR = REPO_ROOT / "release" / "runtime"
BACKUP_DIR = REPO_ROOT / "output" / "backup"

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


def build_magisk(stock_path: str, magisk_apk: str):
    log("=== Building Magisk-patched boot image ===")
    RUNTIME_DIR.mkdir(parents=True, exist_ok=True)
    output = os.path.join(RUNTIME_DIR, "magisk_patched_boot.img")
    tmp = "/data/local/tmp/build_magisk"
    adb(f"shell rm -rf {tmp}")
    adb(f"shell mkdir -p {tmp}/magisk")
    log("Pushing stock boot...")
    adb(f'push "{stock_path}" {tmp}/boot.img')
    log("Extracting and pushing Magisk binaries...")
    with tempfile.TemporaryDirectory() as tmpdir:
        import zipfile
        with zipfile.ZipFile(magisk_apk, "r") as z:
            members = [
                "assets/boot_patch.sh", "assets/util_functions.sh",
                "lib/arm64-v8a/libmagiskboot.so",
                "lib/arm64-v8a/libmagiskinit.so",
                "lib/arm64-v8a/libmagisk.so",
                "lib/arm64-v8a/libmagiskpolicy.so",
                "lib/arm64-v8a/libbusybox.so",
                "lib/arm64-v8a/libinit-ld.so",
            ]
            for m in members:
                try:
                    z.extract(m, tmpdir)
                except KeyError:
                    log(f"  [WARN] {m} not found")
        so_dir = os.path.join(tmpdir, "lib", "arm64-v8a")
        if os.path.isdir(so_dir):
            rename = {"libmagiskboot.so": "magiskboot", "libmagiskinit.so": "magiskinit",
                       "libmagisk.so": "magisk", "libmagiskpolicy.so": "magiskpolicy",
                       "libbusybox.so": "busybox", "libinit-ld.so": "init-ld"}
            for old, new in rename.items():
                src = os.path.join(so_dir, old)
                if os.path.exists(src):
                    dst = os.path.join(tmpdir, "assets" if new == "magiskboot" else tmpdir, new)
                    shutil.copy2(src, dst)
                    os.chmod(dst, 0o755)
            shutil.rmtree(so_dir)
        for root, dirs, files in os.walk(tmpdir):
            for f in files:
                fp = os.path.join(root, f)
                adb(f'push "{fp}" {tmp}/magisk/{f}')
    adb(f"shell chmod 755 {tmp}/magisk/*")
    log("Running boot_patch.sh...")
    adb(f"shell sh {tmp}/magisk/boot_patch.sh {tmp}/boot.img")
    adb(f'pull {tmp}/magisk/new-boot.img "{output}"')
    adb(f"shell rm -rf {tmp}")
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
    ksud_local = shutil.which("ksud") or (REPO_ROOT / "ksud")
    if not os.path.exists(str(ksud_local)):
        log("Downloading ksud for KernelSU boot-patch...")
        url = ("https://github.com/KernelSU-Next/KernelSU-Next/"
               "releases/download/v3.2.0/ksud-aarch64-linux-android")
        ksud_local = os.path.join(RUNTIME_DIR, "ksud")
        urllib.request.urlretrieve(url, ksud_local)
        os.chmod(ksud_local, 0o755)
    log("Pushing ksud to device...")
    adb(f'push "{ksud_local}" {tmp}/ksud')
    adb(f"shell chmod 755 {tmp}/ksud")
    log("Running ksud boot-patch...")
    adb(f"shell {tmp}/ksud boot-patch "
        f"-b {tmp}/boot.img "
        f"-m {tmp}/kernelsu.ko "
        f"-o {tmp}/ "
        f"--out-name kernelsu_patched_boot.img")
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


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Build release artifacts for RMX3760")
    parser.add_argument("--magisk", help="Path to Magisk APK")
    parser.add_argument("--kernelsu", help="Path to kernelsu.ko")
    parser.add_argument("--stock", help="Path to stock boot image")
    parser.add_argument("--all", action="store_true", help="Build everything available")
    args = parser.parse_args()

    if args.all:
        stock = args.stock or find_stock_boot()
        if not stock:
            log("[ERROR] No stock boot image. Use --stock.")
            sys.exit(1)
        images = {}
        magisk_apk = str(REPO_ROOT / "tools" / "apk" / "Magisk-v30.7.apk")
        if os.path.exists(magisk_apk):
            images["magisk_patched_boot.img"] = build_magisk(str(stock), magisk_apk)
        else:
            log(f"[SKIP] Magisk APK not found: {magisk_apk}")
        kernelsu_ko = str(REPO_ROOT / "kernelsu.ko")
        if os.path.exists(kernelsu_ko):
            images["kernelsu_patched_boot.img"] = build_kernelsu(str(stock), kernelsu_ko)
        else:
            log(f"[SKIP] kernelsu.ko not found: {kernelsu_ko}")
        if images:
            write_metadata(images)
        else:
            log("[ERROR] Nothing to build")
            sys.exit(1)
    else:
        stock = args.stock or find_stock_boot()
        if not stock:
            log("[ERROR] No stock boot image. Use --stock.")
            sys.exit(1)
        images = {}
        if args.magisk:
            images["magisk_patched_boot.img"] = build_magisk(str(stock), os.path.abspath(args.magisk))
        if args.kernelsu:
            images["kernelsu_patched_boot.img"] = build_kernelsu(str(stock), os.path.abspath(args.kernelsu))
        if not images:
            parser.print_help()
            sys.exit(1)
        write_metadata(images)
