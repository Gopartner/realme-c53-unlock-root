#!/usr/bin/env python3
"""
Build Release Pipeline
======================
Run by the developer (or CI) to produce safe release artifacts.

No live patching on user devices — all patching happens here.
Output goes to release/runtime/ with checksums in metadata.txt.

Usage:
    python release/build_release.py --kernelsu path/to/kernelsu.ko --stock path/to/stock_boot.img
"""

import argparse
import hashlib
import os
import shutil
import subprocess
import sys
import urllib.request
from datetime import datetime
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
RUNTIME_DIR = REPO_ROOT / "release" / "runtime"
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
        import urllib.request
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
    parser = argparse.ArgumentParser(description="Build KernelSU release for RMX3760")
    parser.add_argument("--kernelsu", required=True, help="Path to kernelsu.ko")
    parser.add_argument("--stock", help="Path to stock boot image")
    args = parser.parse_args()
    stock = args.stock or find_stock_boot()
    if not stock:
        log("[ERROR] No stock boot image. Use --stock.")
        sys.exit(1)
    kernelsu_ko = os.path.abspath(args.kernelsu)
    if not os.path.exists(kernelsu_ko):
        log(f"[ERROR] kernelsu.ko not found: {kernelsu_ko}")
        sys.exit(1)
    image = build_kernelsu(str(stock), kernelsu_ko)
    write_metadata({"kernelsu_patched_boot.img": image})
