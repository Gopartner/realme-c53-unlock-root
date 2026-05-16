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

```
./scripts/backup.sh
```

This saves your media files (DCIM, Pictures, Download, etc.) and dumps the stock boot image.

### 2. Install SPRD Driver

Install the driver from `tools/driver/SPD_Driver_R4.20.4201.zip` before proceeding with unlock.

### 3. Enter SPRD U2S Diag Mode

1. Power off phone completely
2. Connect USB cable to PC
3. Hold **both volume keys**, then tap **power button** for ~1 second and release power
4. Keep holding volume keys — device will appear as **SPRD U2S Diag (COM3)**

### 4. Unlock Bootloader

All tools are in `tools/unlock/`. Run the unlock script:

```
./scripts/unlock.sh
```

The script will:
1. Dump bootchain partitions (PGPT, SPL, uboot)
2. Generate patched SPL via `gen_spl-unlock.exe`
3. Erase SPL and write cboot
4. **Wait for you to do the screwdriver trick** (hold both vol keys + tap power)
5. Execute unlock payload (`spl-unlock.bin`)
6. Restore original SPL and uboot (no button pressing needed)
7. Wipe misc partition (bootloader now unlocked)

Verify: `miscdata.bin` should contain non-zero data.

### 5. Dump Stock Boot Image

After phone reboots (factory reset), set up Android and enable USB debugging:

```
./scripts/backup.sh
```

Or manually:
```
adb shell dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.img
adb pull /data/local/tmp/boot.img stock_boot.img
```

### 6. Root with Magisk (recommended)

```
./scripts/root_magisk.sh
```

The script will:
1. Install Magisk app on phone
2. Extract Magisk binaries from the APK
3. Push stock boot image + Magisk files to phone
4. Patch boot image with Magisk (creates new ramdisk with magiskinit)
5. Flash patched boot to both `boot_a` and `boot_b`
6. Reboot

After reboot, open **Magisk** app → **Superuser** → Grant root to **Shell**.

```
adb shell su -c id
# -> uid=0(root)
```

### 7. Root with KernelSU (LKM)

Requires building `kernelsu.ko` from kernel source (see `scripts/root_kernelsu.sh`).

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
