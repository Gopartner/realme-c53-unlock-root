#!/usr/bin/env python3
"""
Host-side boot image patcher — no ADB/device required.

Downloads the correct ksud binary for the host platform and patches
boot images locally. Supports KernelSU boot-patch without needing magiskboot.

Usage:
    python release/build/host_patch.py --kernelsu kernelsu.ko --stock boot.img -o patched.img
"""

import hashlib
import os
import platform
import shutil
import subprocess
import sys
import urllib.request
from pathlib import Path


RELEASE_DIR = Path(__file__).resolve().parents[1]
RUNTIME_DIR = RELEASE_DIR / "runtime"
TOOLS_DIR = RUNTIME_DIR / ".host_tools"


def log(msg):
    print(f"[HOST] {msg}")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()


def detect_ksud_url():
    machine = platform.machine().lower()
    system = platform.system().lower()
    if system == "linux" and machine in ("x86_64", "amd64"):
        return "ksud-x86_64-linux-gnu"
    if system == "linux" and machine in ("aarch64", "arm64"):
        return "ksud-aarch64-linux-android"
    if system == "darwin" and machine in ("x86_64", "amd64"):
        return "ksud-x86_64-apple-darwin"
    if system == "darwin" and machine in ("arm64", "aarch64"):
        return "ksud-aarch64-apple-darwin"
    return None


def download_ksud(version: str = "v3.2.0"):
    base = "https://github.com/KernelSU-Next/KernelSU-Next/releases/download"
    binary = detect_ksud_url()
    if not binary:
        log("[WARN] No ksud binary for this platform. Install manually.")
        return None
    TOOLS_DIR.mkdir(parents=True, exist_ok=True)
    dest = TOOLS_DIR / "ksud"
    if dest.exists():
        log(f"ksud already cached: {dest}")
        return str(dest)
    url = f"{base}/{version}/{binary}"
    log(f"Downloading ksud ({binary})...")
    urllib.request.urlretrieve(url, dest)
    dest.chmod(0o755)
    log(f"[OK] ksud saved: {dest}")
    return str(dest)


def patch_kernelsu(stock_path: str, kernelsu_ko: str, output: str, ksud_path: str | None = None):
    if not ksud_path:
        ksud_path = shutil.which("ksud")
    if not ksud_path:
        ksud_path = download_ksud()
    if not ksud_path:
        log("[ERROR] No ksud available. Cannot patch.")
        return False
    log("Patching boot image with KernelSU...")
    cmd = [
        ksud_path, "boot-patch",
        "-b", stock_path,
        "-m", kernelsu_ko,
        "-o", os.path.dirname(output),
        "--out-name", os.path.basename(output),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        log(f"[ERROR] ksud failed:\n{result.stdout}\n{result.stderr}")
        return False
    if not os.path.exists(output):
        log(f"[ERROR] Output not created: {output}")
        return False
    log(f"[OK] Patched boot: {output} ({os.path.getsize(output)} bytes)")
    return True


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Host-side boot image patcher")
    parser.add_argument("--kernelsu", required=True, help="Path to kernelsu.ko")
    parser.add_argument("--stock", required=True, help="Path to stock boot.img")
    parser.add_argument("-o", "--output", help="Output path")
    parser.add_argument("--ksud", help="Path to ksud binary (optional)")
    args = parser.parse_args()

    stock = os.path.abspath(args.stock)
    if not os.path.exists(stock):
        log(f"[ERROR] Stock boot not found: {stock}")
        sys.exit(1)
    ksu = os.path.abspath(args.kernelsu)
    if not os.path.exists(ksu):
        log(f"[ERROR] kernelsu.ko not found: {ksu}")
        sys.exit(1)

    output = args.output or os.path.join(RUNTIME_DIR, "kernelsu_patched_boot.img")
    os.makedirs(os.path.dirname(output), exist_ok=True)

    success = patch_kernelsu(stock, ksu, output, args.ksud)
    if not success:
        sys.exit(1)

    print(f"\n[SHA256] {sha256(output)}")
