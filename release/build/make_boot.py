#!/usr/bin/env python3
"""
Pure-Python Android boot image (header v4) builder — no magiskboot needed.

Reconstructs a boot image that is byte-compatible with the stock
Realme C53 (RMX3760, A14 / kernel 5.4.254) boot partition layout:

    page 0   : header (1584 bytes, zero-padded to 4096)
    page 1+  : kernel (raw ARM64 Image)
    padded   : ramdisk (lz4_legacy cpio, kept byte-identical from stock)
    padded   : optional zero-fill to the requested image size

Header fields (kernel_size) are taken verbatim from a stock header
template so os_version / header_size / header_version are preserved
exactly as the stock bootloader expects.

Usage:
    python release/build/make_boot.py \
        --kernel arch/arm64/boot/Image \
        --header stock_a14_header.bin \
        --ramdisk stock_a14_ramdisk.lz4 \
        --size 67108864 \
        -o boot.img
"""

import argparse
import os
import struct
import sys

MAGIC = b"ANDROID!"
BOOT_MAGIC_SIZE = 8
PAGE_SIZE = 4096
HEADER_SIZE = 1584


def log(msg):
    print(f"[BOOT] {msg}")


def read_exact(path):
    with open(path, "rb") as f:
        return f.read()


def parse_header(header):
    if header[:BOOT_MAGIC_SIZE] != MAGIC:
        raise ValueError("not an ANDROID! boot image")
    kernel_size, ramdisk_size = struct.unpack("<II", header[8:16])
    os_version, header_size = struct.unpack("<II", header[16:24])
    header_version = struct.unpack("<I", header[40:44])[0]
    return {
        "kernel_size": kernel_size,
        "ramdisk_size": ramdisk_size,
        "os_version": os_version,
        "header_size": header_size,
        "header_version": header_version,
    }


def build_boot(kernel_bytes, ramdisk_bytes, header_template, size=0):
    # Validate the template before reusing it
    info = parse_header(header_template[:HEADER_SIZE])
    log(f"template header: ver={info['header_version']} "
        f"os_version={hex(info['os_version'])} header_size={info['header_size']}")

    # Header template keeps every field; only kernel_size changes.
    header = bytearray(header_template[:HEADER_SIZE])
    if len(header) < HEADER_SIZE:
        header += b"\x00" * (HEADER_SIZE - len(header))
    struct.pack_into("<I", header, 8, len(kernel_bytes))
    struct.pack_into("<I", header, 12, len(ramdisk_bytes))

    def pad_page(buf):
        pad = (PAGE_SIZE - (len(buf) % PAGE_SIZE)) % PAGE_SIZE
        return buf + b"\x00" * pad

    img = pad_page(bytes(header))
    img += kernel_bytes
    img = pad_page(img)
    img += ramdisk_bytes
    img = pad_page(img)

    if size and len(img) < size:
        img += b"\x00" * (size - len(img))
    return img


def main():
    parser = argparse.ArgumentParser(description="Build a v4 boot image")
    parser.add_argument("--kernel", required=True, help="Path to raw ARM64 kernel Image")
    parser.add_argument("--header", required=True, help="Stock header template (first 1584 bytes)")
    parser.add_argument("--ramdisk", required=True, help="Stock ramdisk blob (lz4_legacy)")
    parser.add_argument("--size", type=int, default=0, help="Final image size (zero-padded)")
    parser.add_argument("-o", "--output", required=True, help="Output boot image path")
    args = parser.parse_args()

    kernel = read_exact(args.kernel)
    ramdisk = read_exact(args.ramdisk)
    header = read_exact(args.header)

    img = build_boot(kernel, ramdisk, header, args.size)
    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    with open(args.output, "wb") as f:
        f.write(img)
    log(f"[OK] {args.output} ({len(img)} bytes, kernel={len(kernel)}, ramdisk={len(ramdisk)})")


if __name__ == "__main__":
    sys.exit(main())
