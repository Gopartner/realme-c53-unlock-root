# AGENTS.md — Realme C53 (RMX3760) Unlock & Root Guide for AI

## Device Identity
- **Model**: Realme C53 (RMX3760)
- **SoC**: Unisoc T612 (ums9230)
- **Kernel**: `5.15.178-android13-8` (non-GKI)
- **Android**: 15 (AP3A.240905.015.A2)
- **Build**: `realme/RMX3760/RE58C2:15/AP3A.240905.015.A2/T.R4T2.1773288057:user/release-keys`
- **Arch**: aarch64, ARM Cortex-A55 (6x) + A78 (2x)
- **Slots**: A/B (`boot_a`/`boot_b`, `init_boot_a`/`init_boot_b`)

## Quickstart (Jangan lupa!)

```bash
# 1. Activate environment & set Git Bash fix
export MSYS2_ARG_CONV_EXCL="*"

# 2. BUILD KernelSU boot image (developer — sekali saja atau setelah backup baru)
python release/build_release.py --kernelsu downloads/kernelsu.ko --stock output/backup/stock_boot_*.img

# 3. Verifikasi artifact sebelum flash
python release/build/verify_release.py

# 4. Jalankan CLI tool (end-user)
python cli.py
# Menu: 1) check env → 2) validate device → 3) backup → 4) driver → 5) unlock → 6) flash KernelSU → 7) verify
```

### Alur kerja utama

| Siapa | Perintah | Apa yang terjadi |
|-------|----------|-----------------|
| **Developer** | `python release/build_release.py --kernelsu kernelsu.ko --stock ...` | Patch stock boot dengan KernelSU LKM, simpan ke `release/runtime/` + `metadata.txt` |
| **Developer** | `python release/build/verify_release.py` | Cek SHA256 semua artifact di `release/runtime/` cocok dengan `metadata.txt` |
| **End-user** | `python cli.py` → pilih 5 | Unlock bootloader via CVE-2022-38694 (SPRD diag mode) |
| **End-user** | `python cli.py` → pilih 6 | Flash KernelSU image (test-boot dulu, baru commit) |
| **Pertama kali buka repo** | `python cli.py` | Python stdlib only, no dependencies |

## Working Directory
```
D:\realme-c53-unlock-root\
```

## Repository Architecture (Refactored v2.0.0)

### Structure
```
D:\realme-c53-unlock-root\
├── src/rmx_unlock/          # Modular Python package (all logic)
│   ├── __init__.py          # Package metadata
│   ├── __main__.py          # `python -m src.rmx_unlock`
│   ├── config.py            # Paths, constants, device info
│   ├── logger.py            # Structured logging (sessions)
│   ├── adb.py               # ADB & Fastboot wrappers
│   ├── validation.py        # Env/device checks, SHA256 verify
│   ├── backup.py            # Stock boot image backup
│   ├── flash.py             # Safer flashing with test-boot
│   ├── metadata.py          # Release metadata parser
│   ├── driver.py            # SPD driver installer
│   ├── exceptions.py        # Custom exception hierarchy
│   └── cli.py               # Thin orchestrator menu
├── release/
│   ├── build_release.py     # BUILD STAGE: patch stock→release images
│   └── build/
│       └── verify_release.py# Verify integrity of release artifacts
├── cli.py                   # Thin entry point (calls src/rmx_unlock)
├── pyproject.toml            # Package metadata
├── output/
│   ├── backup/              # Stock boot backups
│   └── logs/                # Session logs
└── tools/
    ├── unlock/              # CVE-2022-38694 unlock tool
    ├── apk/                 # Magisk APK, KernelSU APK
    └── driver/              # SPRD driver
```

### Key Design Decisions
- **No live patching**: All boot image patching happens in BUILD stage (`release/build_release.py`), not on end-user devices
- **CLI is orchestrator only**: `cli.py` just imports modules — no inline patching logic
- **Safer flashing**: `flash_kernelsu()` does `fastboot boot` (test) before `fastboot flash` (commit)
- **Checksum verification**: Release artifacts include SHA256 in `metadata.txt`, verified before flash
- **Structured logging**: All sessions logged to `output/logs/session_YYYYMMDD.log` with CMD/INFO/WARN/ERROR levels

## Key Paths (Old — for reference, some may still exist)
| Item | Path |
|------|------|
| Backup | `D:\realme-c53-unlock-root\output\backup\` |
| Stock boot | `D:\realme-c53-unlock-root\output\backup\stock_boot_*.img` |
| Release artifacts | `D:\realme-c53-unlock-root\release\runtime\` |
| Unlock tool | `D:\realme-c53-unlock-root\tools\unlock\` (CVE-2022-38694) |
| SPRD driver | `D:\realme-c53-unlock-root\tools\driver\` |
| Kernel source | `https://github.com/realme-kernel-opensource/realme_C51_C53_Note50_C60_C51_N53-AndroidU-kernel-source` |

## Git Bash Path Mangling Fix
Git Bash converts `/data/local/tmp/` to `C:/Program Files/Git/data/local/tmp/`. Always use:
```bash
export MSYS2_ARG_CONV_EXCL="*"
# Then run adb commands normally
```

## Release Build Pipeline (Developer)

Patching is done in BUILD stage — NOT on end-user devices:

```bash
# Build all available release artifacts
python release/build_release.py --all

# Or specify individual components
python release/build_release.py --magisk tools/apk/Magisk-v30.7.apk --stock output/backup/stock_boot_20250101_120000.img
python release/build_release.py --kernelsu kernelsu.ko --stock output/backup/stock_boot_20250101_120000.img

# Verify release artifacts
python release/build/verify_release.py
```

Output goes to `release/runtime/` with `metadata.txt` containing SHA256 checksums.

## End-User Flow (CLI Tool)

```bash
python cli.py
# Menu options:
#   1) Check environment (adb/fastboot)
#   2) Validate device (RMX3760 check)
#   3) Backup stock boot image
#   4) Install SPD driver
#   5) Flash KernelSU (with test-boot safety)
#   6) Flash Magisk
#   7) Verify root access
#   8) Show release metadata
```

## Step 1: Backup Data (Manual)
```bash
export MSYS2_ARG_CONV_EXCL="*"
adb shell "mkdir -p /sdcard/backup_media && cp -r /sdcard/DCIM /sdcard/backup_media/ && cp -r /sdcard/Pictures /sdcard/backup_media/ && cp -r /sdcard/Download /sdcard/backup_media/"
adb pull //sdcard/backup_media/ "D:/realme-c53-unlock-root/backup/"
```

## Step 2: Unlock Bootloader (CVE-2022-38694)
**Tool**: `https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader` (release 1.72)

### Prerequisites
- Install SPRD driver (CLI option 4 or manual `D:\realme-c53-unlock-root\tools\driver\`)
- Device shows as **SPRD U2S Diag (COM3)** in Device Manager
- `spd_dump.exe` needs `Channel9.dll` and `Channel.ini` in working dir

### Sub-steps
1. **Dump partitions**:
   ```
   cd tools\unlock
   spd_dump.exe dump 0x00000000 0x00002000 pgpt.bin
   spd_dump.exe dump 0x00002000 0x00006000 splloader.bin  
   spd_dump.exe dump 0x0000c000 0x00004000 uboot_a.bin
   ```
2. **Generate patched SPL**: `gen_spl-unlock.exe uboot_a.bin`
3. **Erase + write cboot**:
   ```
   spd_dump.exe erase 0x00002000 0x00006000
   spd_dump.exe write 0x00002000 rmx3762/fdl2-cboot.bin
   ```
4. **Screwdriver+PowerOff**: Hold both vol keys, tap power 1s, release power
5. **Run unlock payload**: `spd_dump.exe write 0x00002000 spl-unlock.bin`
6. **Restore & wipe**:
   ```
   spd_dump.exe write 0x00002000 u-boot-spl-16k-sign.bin
   spd_dump.exe write 0x0000c000 uboot_bak.bin
   spd_dump.exe erase 0x0000e000 0x00002000
   ```
7. **Verify**: `spd_dump.exe dump 0x0000e000 0x00000001 miscdata.bin` → non-zero = unlocked

## Step 3: Dump Stock Boot (CLI option 3)
```bash
export MSYS2_ARG_CONV_EXCL="*"
python cli.py  # then choose option 3
# Or manually:
adb shell "dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.img"
adb pull //data/local/tmp/boot.img "D:/realme-c53-unlock-root/output/backup/stock_boot_$(date +%Y%m%d_%H%M%S).img"
```

## Step 4: Root with Magisk (Build Stage)
```bash
# BUILD: patch stock boot → release artifact
python release/build_release.py --magisk tools/apk/Magisk-v30.7.apk --stock output/backup/stock_boot_*.img

# FLASH on device:
python cli.py  # option 6
```

## Step 5: Root with KernelSU (Build Stage)
```bash
# BUILD: patch stock boot with kernelsu.ko → release artifact
python release/build_release.py --kernelsu kernelsu.ko --stock output/backup/stock_boot_*.img

# FLASH on device (with test-boot safety):
python cli.py  # option 5
```

## Grant Root Permission
```bash
adb shell su -c id  # Will show "Access denied" until granted
```
- Open **Magisk** (or KernelSU Next) on phone → **Superuser** tab → Grant **Shell
## Kernel Source Notes
- **`kernel_source/`** = Realme GPL source (Linux **5.4.254**) — WRONG version, device runs 5.15.178
- **`kernel_ack_5.15/`** = ACK android14-5.15 (**5.15.178-android13-8**) — correct base for KernelSU LKM build
- The `.config` in repo root was dumped from device (5.15.178) — useful as reference only
- Realme GPL source is Linux 5.4-based and CANNOT build a 5.15 kernel

## KernelSU LKM Build
- **Do NOT** use `kernel_source/` (it's 5.4, wrong architecture)
- Build against `kernel_ack_5.15/` or fresh ACK android14-5.15 clone
- GitHub Actions workflow: `.github/workflows/build_kernelsu_module.yml`
- The `CONFIG_LOCALVERSION` must match device's exact UTS_RELEASE
- To find device vermagic: `adb shell 'cat /proc/version | grep -o "5\.15\.[^ ]*"'`
- Build with `CONFIG_LOCALVERSION_AUTO=n` for a clean `5.15.178-android13-8` vermagic
- Fallback: `insmod -f kernelsu.ko` forces load despite vermagic mismatch

## Notes for AI
- Use `export MSYS2_ARG_CONV_EXCL="*"` before ALL adb commands on Git Bash
- `adb pull` from `/sdcard` needs `//sdcard/` prefix (double slash)
- magiskd must be running after boot (check `ps -A | grep magiskd`)
- Stock boot.img has **no ramdisk** (RAMDISK_SZ: 0) — Magisk creates one
- Pre-built KernelSU LKM modules are incompatible (vermagic mismatch: 5.15.202 vs 5.15.178)
- Always flash BOTH boot_a and boot_b for slot safety
- `fastboot flash boot` fails — use `fastboot flash boot_a` / `fastboot flash boot_b`
- **Refactored v2.0.0**: CLI is orchestrator only; patching moved to `release/build_release.py` (BUILD stage)
- **Safer flashing**: `flash_kernelsu()` tests boot via `fastboot boot` before flashing
- **Checksums**: Release artifacts verified against `release/runtime/metadata.txt` before any flash
- **Module location**: All logic lives in `src/rmx_unlock/`, root `cli.py` is thin entry point
- `python release/build_release.py --all` to regenerate all patched images from stock boot
