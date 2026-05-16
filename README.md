# Realme C53 (RMX3760) — Bootloader Unlock & Root Guide

Complete guide to unlock bootloader (via CVE-2022-38694) and gain root access
on Realme C53 / RMX3760 (Unisoc T612).

> **Bahasa Indonesia?** Lihat [`README.id.md`](README.id.md) untuk panduan dalam bahasa Indonesia.

## Device Specifications

| Spec | Value |
|------|-------|
| Model | Realme C53 (RMX3760) |
| SoC | Unisoc T612 (ums9230_hulk) |
| CPU | 2x Cortex-A75 + 6x Cortex-A55 |
| RAM | 8 GB |
| Storage | 256 GB |
| Display | 720x1600 HD+, 320 dpi |
| Kernel | 5.15.178-android13-8 |
| Android | 15 (SDK 35) |
| Arch | arm64-v8a |
| Manufacturer | realme |
| Build | AP3A.240905.015.A2 |
| Slots | A/B (boot_a/boot_b, init_boot_a/init_boot_b) |

## Requirements

- Windows PC (or any OS with ADB/fastboot)
- USB cable (data transfer capable)
- SPRD USB driver — included in `tools/driver/`
- ~30 minutes

## Repository Contents

```
realme-c53-unlock-root/
├── README.md                    # English guide
├── README.id.md                 # Bahasa Indonesia guide
├── AGENTS.md                    # AI agent reference
├── scripts/
│   ├── backup.sh                # Backup data before unlock
│   ├── unlock.sh                # Unlock bootloader procedure
│   ├── root_magisk.sh           # Root with Magisk
│   └── root_kernelsu.sh         # Root with KernelSU LKM
├── tools/
│   ├── unlock/                  # CVE-2022-38694 unlock tool (spd_dump, etc.)
│   ├── driver/                  # SPRD USB driver for Windows
│   └── apk/                     # Magisk & KernelSU Next APKs
├── images/
│   └── stock_boot.img           # Stock boot image (64 MB)
└── files/
    └── partition_layout.txt     # Partition table
```

All tools and files are included — no need to download anything else.

## Methods

This guide covers **two** root methods:

1. **Magisk** (recommended, simpler) — Works via init ramdisk patching
2. **KernelSU** (LKM mode) — Requires building kernel module from source

## Quick Start

### 1. Backup Data

**WARNING:** Unlocking bootloader wipes the device. Backup your important data before proceeding.

Run `scripts/backup.sh` or manually:
```
adb shell cp -r /sdcard/DCIM /sdcard/Download /sdcard/Pictures /sdcard/backup/
adb pull /sdcard/backup/ ./backup/
```

### 2. Install SPRD Driver

Install the driver from `tools/driver/SPD_Driver_R4.20.4201.zip` before proceeding with unlock.

### 3. Unlock Bootloader

Uses [CVE-2022-38694](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader)
exploit by TomKing062. All required files are in `tools/unlock/`.

1. Install SPRD driver (`tools/driver/`)
2. Power off phone
3. Short-circuit the motherboard to enter SPRD U2S Diag mode (COM3)
4. Run unlock procedure (see `scripts/unlock.sh`)

### 4. Dump Stock Boot Image (if not using provided one)

A stock boot image is already included at `images/stock_boot.img`.
To dump your own (same device, same build):
```
adb shell dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.img
adb pull /data/local/tmp/boot.img stock_boot.img
```

### 5. Root with Magisk

```
# Install Magisk app on phone
adb install tools/apk/Magisk-v30.7.apk

# Push stock boot to phone
adb push images/stock_boot.img /data/local/tmp/boot.img

# Extract and push Magisk files, then patch
# (See scripts/root_magisk.sh for full automated steps)

# Flash patched boot
adb reboot bootloader
fastboot flash boot_a magisk_patched_boot.img
fastboot flash boot_b magisk_patched_boot.img
fastboot reboot
```

Open Magisk app → Superuser → Grant root to Shell.

### 6. Root with KernelSU (LKM)

Requires building `kernelsu.ko` from kernel source for matching vermagic.

```
# Install KernelSU Next app
adb install tools/apk/KernelSU_Next.apk

# Build kernel module from source, then:
adb shell /data/local/tmp/ksud boot-patch \
    -b /data/local/tmp/boot.img \
    -m /data/local/tmp/kernelsu.ko \
    --magiskboot /data/local/tmp/magiskboot \
    -o /data/local/tmp/ --out-name kernelsu_patched_boot.img
```

See `scripts/root_kernelsu.sh` for details.

## Partition Layout

| Partition | Size | Description |
|-----------|------|-------------|
| boot_a/boot_b | 64 MB | Kernel + DTB (no ramdisk) |
| init_boot_a/b | 8 MB | Ramdisk (init scripts) |
| vendor_boot | 100 MB | Vendor ramdisk |
| super | 8000 MB | System, product, vendor |
| userdata | rest | User data |
| miscdata | 1 MB | Bootloader unlock flag |

Full layout in `files/partition_layout.txt`.

## Kernel Source

```
https://github.com/realme-kernel-opensource/realme_C51_C53_Note50_C60_C51_N53-AndroidU-kernel-source
```

Note: Contains `drivers/gpu/drm/nouveau/nvkm/subdev/i2c/aux.c` and
`include/soc/arc/aux.h` which are reserved filenames on Windows.
Use WSL/Linux to clone.

## Credits

- [TomKing062](https://github.com/TomKing062) — CVE-2022-38694 unlock exploit
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) — KernelSU Next
- [topjohnwu](https://github.com/topjohnwu/Magisk) — Magisk
- Realme Open Source — Kernel source code
- [opencode](https://opencode.ai) — AI coding agent that assisted with the unlock bootloader, root process, and documentation
- opencode/big-pickle — Model powering the AI agent

## License

This documentation is provided for educational purposes.
Use at your own risk.
