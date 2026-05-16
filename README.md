# Realme C53 (RMX3760) — Bootloader Unlock & Root Guide

Complete guide to unlock bootloader (via CVE-2022-38694) and gain root access
on Realme C53 / RMX3760 (Unisoc T612).

## Device Specifications

| Spec | Value |
|------|-------|
| Model | Realme C53 (RMX3760 / RMX3762) |
| SoC | Unisoc T612 (ums9230) |
| CPU | 2x Cortex-A78 + 6x Cortex-A55 |
| GPU | Mali-G57 |
| Kernel | 5.15.178-android13-8 (non-GKI) |
| Android | 15 (AP3A.240905.015.A2) |
| Storage | 64 GB / 128 GB eMMC |
| RAM | 4 GB / 6 GB |
| Arch | aarch64 |
| Slots | A/B (boot_a/boot_b, init_boot_a/init_boot_b) |

## Requirements

- Windows PC (or any OS with ADB/fastboot)
- USB cable (data transfer capable)
- SPRD USB driver (for unlock step)
- ~30 minutes

## Methods

This guide covers **two** root methods:

1. **Magisk** (recommended, simpler) — Works via init ramdisk patching
2. **KernelSU** (LKM mode) — Requires building kernel module from source

## Quick Start

### 1. Backup Data

```
adb shell mkdir -p /sdcard/backup
adb shell cp -r /sdcard/DCIM /sdcard/backup/
adb shell cp -r /sdcard/Pictures /sdcard/backup/
adb shell cp -r /sdcard/WhatsApp /sdcard/backup/
adb pull /sdcard/backup/ ./backup/
```

Also enable Google Backup:
```
adb shell settings put secure backup_enabled 1
adb shell bmgr run
```

### 2. Unlock Bootloader

Use [CVE-2022-38694](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader)
exploit by TomKing062.

1. Install SPRD driver (see `sprd_driver/`)
2. Power off phone
3. Short-circuit the motherboard to enter SPRD U2S Diag mode
4. Run unlock procedure (see `scripts/unlock.sh`)

### 3. Dump Stock Boot Image

```
adb shell dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.img
adb pull /data/local/tmp/boot.img stock_boot.img
```

### 4. Root with Magisk

```
# Push Magisk files to phone
adb push stock_boot.img /data/local/tmp/
adb shell /data/local/tmp/magisk/boot_patch.sh /data/local/tmp/boot.img
adb pull /data/local/tmp/magisk/new-boot.img magisk_patched_boot.img

# Flash
adb reboot bootloader
fastboot flash boot_a magisk_patched_boot.img
fastboot flash boot_b magisk_patched_boot.img
fastboot reboot
```

Open Magisk app → Superuser → Grant root to Shell.

### 5. Root with KernelSU (LKM)

Requires building `kernelsu.ko` from kernel source for matching vermagic.

```
git clone <kernel_source_url>
cd kernel_source
# Add KernelSU as submodule
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/main/kernel/setup.sh" | bash -
# Build only the module
make ARCH=arm64 CC=clang LLVM=1 modules_prepare
make ARCH=arm64 CC=clang LLVM=1 M=KernelSU modules
# Use ksud to patch boot image with the .ko
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

## License

This documentation is provided for educational purposes.
Use at your own risk.
