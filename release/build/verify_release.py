#!/usr/bin/env python3
"""
Release Artifact Verification
=============================
Verifies integrity of release/runtime/ artifacts.

Usage:
    python release/build/verify_release.py
"""

import hashlib
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
RUNTIME_DIR = REPO_ROOT / "release" / "runtime"
METADATA_FILE = RUNTIME_DIR / "metadata.txt"


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        while chunk := f.read(8192):
            h.update(chunk)
    return h.hexdigest()


def verify():
    errors = 0
    if not METADATA_FILE.exists():
        print(f"[ERROR] Metadata not found: {METADATA_FILE}")
        sys.exit(1)
    metadata = {}
    with open(METADATA_FILE) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" not in line:
                continue
            k, _, v = line.partition("=")
            metadata[k.strip()] = v.strip()
    for key, expected in metadata.items():
        if not key.startswith("SHA256_"):
            continue
        filename = key[len("SHA256_"):]
        filepath = RUNTIME_DIR / filename
        if not filepath.exists():
            print(f"[FAIL] Missing: {filename}")
            errors += 1
            continue
        actual = sha256(str(filepath))
        if actual == expected:
            print(f"[OK] {filename}")
        else:
            print(f"[FAIL] {filename}: checksum mismatch")
            errors += 1
    if errors:
        print(f"\n{errors} verification(s) FAILED")
        sys.exit(1)
    else:
        print("\nAll artifacts verified successfully.")


if __name__ == "__main__":
    verify()
