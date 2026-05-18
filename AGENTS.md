# AGENTS.md — Realme C53 (RMX3760) Unlock & Root Guide for AI

This file tells the AI agent how to help the user with unlocking, rooting,
building kernel modules, and creating GitHub Releases for Realme C53 (RMX3760).

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

# 2. BUILD KernelSU/Magisk boot image (developer — sekali saja atau setelah backup baru)
python release/build_release.py --kernelsu downloads/kernelsu.ko --stock output/backup/stock_boot_*.img
python release/build_release.py --magisk tools/apk/Magisk-v30.7.apk --stock output/backup/stock_boot_*.img
# Atau build semua: python release/build_release.py --all

# 3. Verifikasi artifact sebelum flash
python release/build/verify_release.py

# 4. GitHub Actions akan build + package Release lengkap:
#    - kernelsu.ko
#    - kernelsu_patched_boot.img (jika stock_boot_url diisi)
#    - tools/unlock/ (CVE-2022-38694)
#    - tools/apk/KernelSU_Next.apk
#    - flash.bat / flash.sh
#    - README.txt
#    Semua di-zip jadi satu file: RMX3760_KernelSU_Release.zip

# 5. Jalankan CLI tool (end-user)
python cli.py
# Menu: 1) check env → 2) validate device → 3) backup → 4) driver → 5) unlock → 6) flash KernelSU → 7) verify
```

### Alur kerja utama

| Siapa | Perintah | Apa yang terjadi |
|-------|----------|-----------------|
| **Developer** | `python release/build_release.py --kernelsu kernelsu.ko --stock ...` | Patch stock boot dengan KernelSU LKM, simpan ke `release/runtime/` + `metadata.txt` |
| **Developer** | `python release/build_release.py --magisk Magisk-v30.7.apk --stock ...` | Patch stock boot dengan Magisk, simpan ke `release/runtime/` + `metadata.txt` |
| **Developer** | `python release/build/verify_release.py` | Cek SHA256 semua artifact di `release/runtime/` cocok dengan `metadata.txt` |
| **Developer** | `python release/build/host_patch.py --kernelsu ksu.ko --stock boot.img` | Patch boot tanpa ADB/device (host-side, Linux x86_64) |
| **Developer** | `python -m pytest tests/ -v` | Jalankan unit tests |
| **Developer** | `pre-commit run --all-files` | Lint & format check |
| **End-user** | `python cli.py` → pilih 5 | Unlock bootloader via CVE-2022-38694 (SPRD diag mode) |
| **End-user** | `python cli.py` → pilih 6 | Flash KernelSU image (test-boot dulu, baru commit) |
| **End-user** | `python cli.py` → pilih 7 | Flash Magisk image (langsung flash kedua slot) |
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

---

# AI Agent Workflows

Below are complete step-by-step workflows the AI can follow autonomously.

## Workflow A: Fork + Build Kernel Module (GitHub Actions)

Use when: user wants to build their own kernelsu.ko via GitHub Actions.

```
1. Ask user: "Do you have a GitHub account?"
   └─ If NO: Guide them to create one at github.com

2. Ask user to fork the repo:
   - Go to https://github.com/Gopartner/realme-c53-unlock-root
   - Click "Fork" button

3. Ask user to run GitHub Actions on their fork:
   - Go to their fork's Actions tab
   - Select "Build KernelSU LKM for Realme C53 (RMX3760)"
   - Click "Run workflow"
   - Optional: Enter vermagic suffix if needed
   - Wait ~15 minutes

4. After workflow completes:
   - Go to Releases page on their fork
   - Download the RMX3760_KernelSU_Release.zip
   - Extract the zip

5. The Release ZIP contains:
   - kernelsu.ko             → kernel module
   - kernelsu_patched_boot.img → ready to flash (if stock URL provided)
   - unlock/                 → bootloader unlock tools
   - apk/KernelSU_Next.apk   → root manager app
   - flash.bat / flash.sh    → one-click flash scripts
   - README.txt              → instructions

6. Tell user: "Keep this Release ZIP safe. You can reuse it anytime
   to root this device again without rebuilding."
```

## Workflow B: Use Existing Release (No Build Needed)

Use when: user doesn't want to build, just wants to root using someone else's Release.

```
1. Check if an existing Release is available:
   - Go to https://github.com/Gopartner/realme-c53-unlock-root/releases
   - OR the user's fork Releases page
   - Look for RMX3760_KernelSU_Release.zip

2. If Release found:
   - Download the ZIP
   - Extract to a folder
   - Continue with Workflow D (Bootloader Unlock)

3. If no Release found:
   - Tell user they need to either:
     a. Fork and build their own (Workflow A)
     b. Ask someone with same device to share their Release

4. ⚠️ IMPORTANT: The kernelsu.ko must match the device kernel version.
   Check vermagic: modinfo -F vermagic kernelsu.ko
   Device kernel: 5.15.178-android13-8
```

## Workflow C: Install SPRD Driver

Use when: user needs to install the USB driver for unlock.

```bash
# Method 1: CLI
python cli.py  # select menu 4

# Method 2: Manual
# Navigate to tools/driver/ folder
# Run DPInst.exe or install.bat as Administrator

# Verify: Device Manager should show "SPRD U2S Diag (COM3)"
# when phone is in download mode
```

## Workflow D: Unlock Bootloader (CVE-2022-38694)

Use when: user wants to unlock the bootloader.

### Prerequisites
- SPRD driver installed (Workflow C)
- Phone OFF, USB cable connected
- Windows PC (spd_dump.exe is Windows-only)

### Steps

```bash
# 0. Set path fix (Git Bash)
export MSYS2_ARG_CONV_EXCL="*"

# 1. Enter download mode
# Power off phone → connect USB → hold both vol keys → tap power 1s → release power
# Device should show as SPRD U2S Diag (COM3)

# 2. Navigate to unlock tool
cd tools/unlock

# 3. Dump bootchain partitions
spd_dump.exe dump 0x00000000 0x00002000 pgpt.bin
spd_dump.exe dump 0x00002000 0x00006000 splloader.bin
spd_dump.exe dump 0x0000c000 0x00004000 uboot_a.bin

# 4. Generate patched SPL
gen_spl-unlock.exe uboot_a.bin

# 5. Erase SPL and write cboot
spd_dump.exe erase 0x00002000 0x00006000
spd_dump.exe write 0x00002000 rmx3762/fdl2-cboot.bin

# 6. ⚠️ SCREWDRIVER TRICK
# Tell user:
#   "Hold BOTH volume keys, tap power button for 1 second, release power.
#    Keep holding volume keys. Press Enter when ready."
input "Press Enter after screwdriver trick..."

# 7. Execute unlock payload
spd_dump.exe write 0x00002000 spl-unlock.bin

# 8. Restore bootchain
spd_dump.exe write 0x00002000 u-boot-spl-16k-sign.bin
spd_dump.exe write 0x0000c000 uboot_bak.bin
spd_dump.exe erase 0x0000e000 0x00002000

# 9. Verify
spd_dump.exe dump 0x0000e000 0x00000001 miscdata.bin
# Non-zero data = unlocked!

# 10. Return to repo root
cd ../..
```

### After Unlock
- Phone will factory reset (this is normal)
- Guide user to set up Android
- Enable Developer Options → USB Debugging
- Continue with Workflow E

### Troubleshooting
| Problem | Fix |
|---------|-----|
| "No device found" | Install/reinstall SPRD driver, check COM port |
| "Connection failed" | Try different USB port, use USB 2.0 |
| Phone not detected after screwdriver | Repeat step 1-6, hold vol keys tighter |
| miscdata.bin is all zeros | Unlock failed, repeat from step 3 |

## Workflow E: Backup Stock Boot Image

Use after unlock, when phone is booted with USB debugging.

```bash
export MSYS2_ARG_CONV_EXCL="*"

# Method 1: CLI
python cli.py  # select menu 3

# Method 2: Manual
adb shell "dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.img"
adb pull //data/local/tmp/boot.img output/backup/stock_boot_$(date +%Y%m%d_%H%M%S).img
```

## Workflow F: Build Patched Boot Image

Use when: user has stock boot image + kernelsu.ko, wants a flashable image.

### KernelSU (recommended)
```bash
python release/build_release.py \
  --kernelsu downloads/kernelsu.ko \
  --stock output/backup/stock_boot_*.img

# Verify
python release/build/verify_release.py
```

### Magisk (alternative)
```bash
python release/build_release.py \
  --magisk tools/apk/Magisk-v30.7.apk \
  --stock output/backup/stock_boot_*.img

# Verify
python release/build/verify_release.py
```

## Workflow G: Flash KernelSU (with Test-Boot Safety)

```bash
export MSYS2_ARG_CONV_EXCL="*"

# Method 1: CLI (recommended)
python cli.py  # select menu 6
# Agent must tell user:
#   "After fastboot boot, check if phone boots normally.
#    If yes, press Enter to flash permanently.
#    If no, press Ctrl+C — phone will reboot normally."

# Method 2: Manual fastboot
adb reboot bootloader
fastboot boot kernelsu_patched_boot.img   # TEST FIRST
# If booted successfully:
fastboot flash boot_a kernelsu_patched_boot.img
fastboot flash boot_b kernelsu_patched_boot.img
fastboot reboot

# After reboot, install APK:
adb install tools/apk/KernelSU_Next.apk
```

## Workflow H: Flash Magisk (Direct)

```bash
export MSYS2_ARG_CONV_EXCL="*"

# Method 1: CLI
python cli.py  # select menu 7

# Method 2: Manual
adb reboot bootloader
fastboot flash boot_a magisk_patched_boot.img
fastboot flash boot_b magisk_patched_boot.img
fastboot reboot

# After reboot, install APK:
adb install tools/apk/Magisk-v30.7.apk
```

## Workflow I: Verify Root

```bash
adb shell su -c id
# Expected: uid=0(root)

# If "Access denied" or "su: not found":
#   1. Open KernelSU Next / Magisk app on phone
#   2. Go to Superuser tab
#   3. Grant root to Shell / ADB Shell
#   4. Try again

# Check KernelSU module loaded:
adb shell lsmod | grep kernelsu

# Check Magisk daemon:
adb shell ps -A | grep magiskd
```

## Workflow J: Create GitHub Release (CI)

Use when: user wants to trigger the automated release pipeline.

```
1. Go to GitHub Actions tab on their fork
2. Select "Build KernelSU LKM for Realme C53 (RMX3760)"
3. Click "Run workflow"
4. Optional inputs:
   - localversion: extra vermagic suffix (usually empty)
   - stock_boot_url: URL to stock boot.img for full release
5. Wait ~15 minutes
6. GitHub automatically creates a Release with:
   RMX3760_KernelSU_Release.zip
   (contains kernelsu.ko + unlock tools + APK + flash scripts + README)
```

---

# Troubleshooting Guide

| Problem | Cause | Solution |
|---------|-------|----------|
| `adb: command not found` | ADB not installed | Install Android Platform Tools |
| `fastboot: command not found` | Fastboot not installed | Install Android Platform Tools |
| `device not detected` | USB debugging off | Enable Developer Options → USB Debugging |
| `SPRD U2S Diag not showing` | Driver not installed | Run driver installer as Admin |
| `flash boot failed` | Bootloader locked | Unlock first (Workflow D) |
| `fastboot flash boot` fails | Wrong slot | Always use `boot_a` and `boot_b` |
| `vermagic mismatch` | Wrong kernel version | Build kernelsu.ko matching device kernel |
| `insmod: failed` | Module incompatible | Use `insmod -f kernelsu.ko` to force load |
| `su: inaccessible` | Root app not running | Open KernelSU Next / Magisk app |
| Permission denied for shell | Root not granted | Grant in app → Superuser |
| `python` not found | Python not installed | Install Python 3.10+ from python.org |
| `ModuleNotFoundError` | Wrong directory | Run commands from repo root |

---

# Kernel Source Notes
- **`kernel_source/`** = Realme GPL source (Linux **5.4.254**) — WRONG version, device runs 5.15.178
- **`kernel_ack_5.15/`** = ACK android14-5.15 (**5.15.178-android13-8**) — correct base for KernelSU LKM build
- The `.config` in repo root was dumped from device (5.15.178) — useful as reference only
- Realme GPL source is Linux 5.4-based and CANNOT build a 5.15 kernel

# KernelSU LKM Build
- **Do NOT** use `kernel_source/` (it's 5.4, wrong architecture)
- Build against `kernel_ack_5.15/` or fresh ACK android14-5.15 clone
- GitHub Actions workflow: `.github/workflows/build_kernelsu_module.yml`
- The `CONFIG_LOCALVERSION` must match device's exact UTS_RELEASE
- To find device vermagic: `adb shell 'cat /proc/version | grep -o "5\.15\.[^ ]*"'`
- Build with `CONFIG_LOCALVERSION_AUTO=n` for a clean `5.15.178-android13-8` vermagic
- Fallback: `insmod -f kernelsu.ko` forces load despite vermagic mismatch

# Notes for AI
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
