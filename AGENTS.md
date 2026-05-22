# AGENTS.md — Realme C53 / Multi-Chipset Unlock & Root Guide for AI

This file is the **constitution** for the AI agent. It defines:
- What this project can do (and what it CANNOT do)
- How to handle any user request — supported or not
- Step-by-step workflows the AI must follow

**Golden rule**: Always stay within this project's scope. If a user asks for something outside scope, tell them honestly what this repo can/cannot do, and redirect if possible. Never pretend the repo supports something it doesn't.

---

## Project Scope — What This Repo CAN Do

| Category | Supported | Details |
|----------|-----------|---------|
| **Bootloader unlock** | ✅ SPRD (Unisoc) | CVE-2022-38694, tools included |
| | ⚠️ MediaTek | BROM mode, tools NOT included (user provides mtkclient) |
| | ⚠️ Qualcomm | EDL / fastboot-oem, tools NOT included |
| | ❌ Xiaomi Mi Unlock | Cannot bypass Xiaomi's waiting period |
| | ❌ Huawei/Honor | Bootloader unlock permanently blocked |
| | ❌ Samsung Knox | Cannot bypass Knox lock |
| **Root method** | ✅ KernelSU LKM | Test-boot safety, requires matching vermagic |
| | ✅ Magisk | Direct flash (no test-boot) |
| | ✅ Hybrid (Magisk+KSU) | **Recommended for RMX3760** — Magisk v27 for root, KSU module loaded via Magisk module |
| **Init_boot** | ✅ Has partition | Stock init_boot contains real init + ramdisk |
| **KSU-only** | ❌ Bug ksud init | KSU init binary fails to load module on devices without stock ramdisk; use hybrid instead |
| **Build kernel module** | ✅ Via GitHub Actions | CI builds kernelsu.ko |
| | ✅ Local build | Via kernel_ack_5.15/ |
| **Device support** | ✅ Any device with a TOML profile | See devices/ directory |

## How the AI Must Handle User Requests

### Scenario A: User has a supported device (SPRD/Unisoc T6xx)
→ Follow AGENTS.md workflows normally. The user is in the right place.

### Scenario B: User has a MediaTek device (Xiaomi, Realme MTK, etc.)
→ Guide them: "This repo has a MediaTek profile template and BROM unlock
flow in CLI menu 5. You'll need mtkclient and MediaTek DA driver.
Unlock via BROM may work if the device doesn't have locked BROM.
Xiaomi MediaTek devices vary — some are unlockable, some aren't."

### Scenario C: User has a Xiaomi device and asks to bypass Mi Unlock waiting period
→ Be direct: "This repo cannot bypass Xiaomi's Mi Unlock waiting period.
The Mi Unlock server-side verification is required for Xiaomi Qualcomm
devices. If your Xiaomi uses MediaTek, BROM unlock may work (see Scenario B).
Otherwise, the official 7-day/30-day wait is mandatory."

### Scenario D: User has an entirely unsupported device (Huawei, Samsung, iPhone, etc.)
→ "This repo is designed for Android devices with Unisoc/MediaTek/Qualcomm
chipsets. Your device is not supported by any tool in this repo.
Here's what I can suggest: [link to known resources for that device]"

### Scenario E: User asks something vague ("root my phone")
→ Ask: "What device model and chipset do you have? Run `adb shell getprop
ro.product.model` and `adb shell getprop ro.board.platform`."
Then direct to the appropriate scenario above.

---

## Conversation Flow — AI Harus Proaktif

AI harus melacak progres percakapan dan otomatis menyarankan langkah
berikutnya tanpa ditanya. Ini aturannya:

### 1. Lacak State Percakapan
```
State: idle → dev → build → test → release
Setiap state punya next-step otomatis.
Simpan state terakhir di memori percakapan.
```

### 2. Deteksi Keberhasilan Otomatis
Ketika AI melihat output sukses (flash OK, root verified, build selesai),
AI HARUS langsung menyarankan langkah berikutnya. Contoh:

| AI melihat | AI harus bilang |
|------------|----------------|
| "Flash selesai, HP boot normal" | "Root udah jalan. Verify `adb shell su -c id` dulu? |
| "Vermagic cocok" | "Build cocok. Mau test-boot sekarang? |
| "Build Actions selesai" | "Artifact siap. Download & extract, lanjut test? |
| "Test gagal (bootloop)" | "Kembali ke Dev Mode, perbaiki dulu. Mau saya cek log?" |

### 3. Jangan Diam Saja
Setelah menjalankan perintah atau memberikan informasi, AI harus
menambahkan 1-2 baris "Lanjutan:" yang menawarkan step berikutnya.

### 4. Jika User Bingung
Jika user jawab singkat ("gitu", "oh", "ok") tanpa arahan jelas, AI
harus tebak state terakhir dan tawarkan step paling logis.

### 5. State Tracker (internal AI)
```
DEV MODE:
  └─ edit selesai → push → trigger build (otomatis suggest)
BUILD MODE:
  └─ build selesai → suggest download → extract → test
TEST MODE:
  └─ test berhasil → suggest buat Release
  └─ test gagal → suggest balik ke Dev Mode
RELEASE MODE:
  └─ release selesai → suggest update end-user docs
```

## Device Identity
- **Model**: Realme C53 (RMX3760)
- **SoC**: Unisoc T612 (ums9230)
- **Kernel**: `5.15.178-android13-8` (non-GKI)
- **Android**: 15 (AP3A.240905.015.A2)
- **Build**: `realme/RMX3760/RE58C2:15/AP3A.240905.015.A2/T.R4T2.1773288057:user/release-keys`
- **Arch**: aarch64, ARM Cortex-A55 (6x) + A78 (2x)
- **Slots**: A/B (`boot_a`/`boot_b`, `init_boot_a`/`init_boot_b`)

## Alur Kerja

Ada 4 mode terpisah. Kerjakan urut:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 DEV MODE      → Kerja di repo (edit tools/metode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 BUILD MODE    → Trigger Actions → build kernelsu.ko + ZIP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 TEST MODE     → Download artifact → flash ke hp → verifikasi
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RELEASE MODE  → Kalau BERHASIL → buat GitHub Release manual
                  Release BARU = tambahan, jangan hapus yg lama
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### DEV MODE — Edit/perbaiki repo

Gunakan saat: mengubah tools, metode, AGENTS.md, workflow, atau  kode Python.

```bash
# 1. Aktifkan env
export MSYS2_ARG_CONV_EXCL="*"

# 2. Jalankan unit tests
python -m pytest tests/ -v

# 3. Lint & format
pre-commit run --all-files

# 4. Build lokal (opsional, verifikasi)
python release/build_release.py --kernelsu downloads/kernelsu.ko --stock output/backup/stock_boot_*.img
python release/build_release.py --magisk tools/apk/Magisk-v30.7.apk --stock output/backup/stock_boot_*.img

# 5. Verifikasi artifact lokal
python release/build/verify_release.py
```

### BUILD MODE — Build kernelsu.ko + bahan root via Actions

Gunakan saat: ingin produksi kernelsu.ko + toolkit untuk di-flash.

```bash
# Cara: Fork repo → trigger Actions manual
# 1. Buka https://github.com/Gopartner/realme-c53-unlock-root
# 2. Klik Fork
# 3. Masuk ke Actions tab fork → "🔧 Build Your Own Release" → Run workflow
# 4. Isi optional: localversion, stock_boot_url
# 5. Tunggu ~15 menit
# 6. Download artifact RMX3760_KernelSU_Release.zip dari halaman Actions
```

### TEST MODE — Flash ke hp & verifikasi

```bash
# 1. Ekstrak artifact ZIP
# 2. Unlock bootloader dulu (lihat Workflow D)
# 3. Flash & test:
python cli.py  # menu 6 → test-boot dulu
# atau manual:
adb reboot bootloader
fastboot boot kernelsu_patched_boot.img   # TEST FIRST
# Kalau boot normal:
fastboot flash boot_a kernelsu_patched_boot.img
fastboot flash boot_b kernelsu_patched_boot.img
fastboot reboot

# 4. Verifikasi root:
adb shell su -c id
adb shell lsmod | grep kernelsu
```

### RELEASE MODE — Buat GitHub Release (hanya jika test BERHASIL)

```bash
# 1. Buka halaman Actions → artifact yang sudah di-test
# 2. Download RMX3760_KernelSU_Release.zip
# 3. Buka repositori → Releases → "Create a new release"
# 4. Isi tag (contoh: release-20260522), judul, notes (sertakan vermagic)
# 5. Upload ZIP sebagai attachment
# 6. Publish — jangan hapus release lama
```

### End-user flow (pakai hasil release)

```bash
# 1. Download Release ZIP dari GitHub Releases
# 2. Ekstrak
# 3. Jalankan CLI:
python cli.py
# Menu: 1) check → 2) validate → 4) driver → 5) unlock → 3) backup → 6) flash → 8) verify
```

## Working Directory
```
D:\realme-c53-unlock-root\
```

## Repository Architecture (Refactored v2.0.0)

### Structure
```
realme-c53-unlock-root/
├── cli.py                       ← Thin entry point (end-user)
├── AGENTS.md                    ← AI agent instructions (10 workflows)
├── AI_PROMPT_TEMPLATE.md        ← Copy-paste prompts for any AI
├── pyproject.toml               ← Package metadata & tool config
├── src/rmx_unlock/              ← Python package (all logic)
│   ├── __init__.py              ← Package init
│   ├── __main__.py              ← `python -m src.rmx_unlock`
│   ├── config.py                ← Paths, constants, device info
│   ├── logger.py                ← Structured logging (sessions)
│   ├── adb.py                   ← ADB & Fastboot wrappers
│   ├── validation.py            ← Env/device checks, SHA256 verify
│   ├── backup.py                 ← Stock boot image backup
│   ├── flash.py                 ← Safer flashing with test-boot
│   ├── unlock.py                ← Bootloader unlock logic
│   ├── metadata.py              ← Release metadata parser
│   ├── driver.py                ← SPD driver installer
│   ├── cli.py                   ← Thin orchestrator menu
│   └── exceptions.py            ← Custom exception hierarchy
├── release/
│   ├── build_release.py         ← BUILD STAGE: patch stock→release
│   ├── runtime/                 ← Build output (gitignored)
│   │   ├── metadata.txt         ← SHA256 checksums
│   │   └── kernelsu_patched_boot.img
│   └── build/
│       ├── flash.bat            ← One-click flash script
│       ├── verify_release.py    ← SHA256 verification
│       └── host_patch.py        ← Patch boot without phone
├── .github/workflows/
│   ├── release.yml             ← CI: build kernelsu.ko + ZIP artifact
│   └── test_python.yml          ← CI: pytest on push/PR
├── tools/
│   ├── unlock/
│   │   ├── sprd/              ← SPRD/Unisoc tools (spd_dump.exe)
│   │   ├── mtk/               ← MediaTek tools (user-provided: mtkclient)
│   │   └── qcom/              ← Qualcomm tools (user-provided: edl)
│   ├── driver/                ← USB drivers per chipset
│   └── apk/                   ← KernelSU Next + Magisk APKs
├── tests/                       ← Pytest unit tests
├── output/                      ← Backups & logs (gitignored)
│   ├── backup/                  ← Stock boot images
│   └── logs/                    ← Session logs
├── devices/                      ← Device profiles (TOML)
│   ├── RMX3760.toml             ← Realme C53 (SPRD)
│   ├── RMX3750.toml             ← Realme C51 (SPRD)
│   ├── example_mediatek.toml    ← MediaTek Helio example
│   ├── example_qualcomm.toml    ← Qualcomm Snapdragon example
│   └── template.toml            ← Template for new devices
├── downloads/                   ← User-provided kernelsu.ko
├── files/                       ← Reference data (partition layout)
├── kernel_ack_5.15/             ← ACK kernel source (local build)
├── kernel_source/               ← Realme GPL source (5.4, reference)
└── toolchain/                   ← Build toolchain (optional)
```

### Key Design Decisions
- **No live patching**: All boot image patching happens in BUILD stage (`release/build_release.py`), not on end-user devices
- **Multi-device + Multi-chipset**: Device profiles in `devices/` (TOML). Add any device (SPRD, MediaTek, Qualcomm) by creating a new profile.
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
| Unlock tool | `D:\realme-c53-unlock-root\tools\unlock\sprd\` (CVE-2022-38694) |
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

## Workflow A: Build Your Own Release (Recommended)

Use when: user wants to build their own kernelsu.ko + toolkit via GitHub Actions.

### BUILD stage
```
1. Ask user: "Do you have a GitHub account?"
   └─ If NO: Guide them to create one at github.com

2. Ask user to fork the repo:
   - Go to https://github.com/Gopartner/realme-c53-unlock-root
   - Click "Fork" button

3. Ask user to run GitHub Actions on their fork:
   - Go to their fork's Actions tab
   - Select "🔧 Build Your Own Release"
   - Click "Run workflow"
   - Optional: Enter vermagic suffix if needed
   - Wait ~15 minutes

4. After workflow completes:
   - Go to the Actions run page (NOT Releases page yet)
   - Download RMX3760_KernelSU_Release.zip artifact
   - Extract the zip

5. The ZIP contains:
   - kernelsu.ko             → kernel module
   - kernelsu_patched_boot.img → ready to flash (if stock URL provided)
   - unlock/                 → bootloader unlock tools
   - apk/KernelSU_Next.apk   → root manager app
   - flash.bat / flash.sh    → one-click flash scripts
   - README.txt              → instructions
```

### TEST stage
```
6. Flash to phone (see Workflow G):
   - fastboot boot kernelsu_patched_boot.img  (test first!)
   - If boots OK → fastboot flash to both slots
   - Verify root: adb shell su -c id

7. If test FAILS (bootloop, no root):
   - Report issue or fix in Dev Mode
   - Do NOT release this build
```

### RELEASE stage
```
8. Only if test PASSES:
   - Go to GitHub → Releases → "Create a new release"
   - Tag: release-YYYYMMDD (e.g. release-20260522)
   - Title: "RMX3760 Release YYYYMMDD"
   - Notes: include vermagic from workflow output
   - Upload the tested ZIP as attachment
   - Publish (jangan hapus release lama)
```

## Workflow B: Use Existing Release (Fallback — Not Recommended)

Use when: user doesn't want to build, just wants to root using a pre-built Release.

```
1. Check if an existing Release is available:
   - Go to https://github.com/Gopartner/realme-c53-unlock-root/releases
   - Look for RMX3760_KernelSU_Release.zip

2. If Release found:
   - Download the ZIP, extract, check vermagic:
     modinfo -F vermagic kernelsu.ko
   - VERMAGIC HARUS COCOK dengan kernel device (5.15.178-android13-8)
   - Jika beda → jangan dipakai, lapor atau build sendiri (Workflow A)

3. If no Release or vermagic mismatch:
   - User harus build sendiri via Workflow A (Fork + Build)
```

⚠️ **Peringatan**: Pre-built release mungkin vermagic-nya beda dengan kernel device kamu. Selalu cek `modinfo -F vermagic kernelsu.ko` sebelum flash.

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

## Workflow D: Unlock Bootloader

Use when: user wants to unlock the bootloader.
The CLI auto-selects the correct method based on the device profile (SPRD, MediaTek, Qualcomm).

### Prerequisites (all chipsets)
- Correct USB driver installed (Workflow C)
- Phone OFF, USB cable connected

### Quick method (all chipsets)
```bash
export MSYS2_ARG_CONV_EXCL="*"
python cli.py            # select menu 5
# CLI will detect chipset from profile and show appropriate steps
```

### SPRD-specific manual method (CVE-2022-38694)

#### Prerequisites
- SPRD driver installed (Workflow C)
- Windows PC (spd_dump.exe is Windows-only)

#### Steps
```bash
# 0. Set path fix (Git Bash)
export MSYS2_ARG_CONV_EXCL="*"

# 1. Enter download mode
# Power off phone → connect USB → hold both vol keys → tap power 1s → release power
# Device should show as SPRD U2S Diag (COM3)

# 2. Navigate to unlock tool
cd tools/unlock/sprd

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
# Hold BOTH volume keys, tap power button for 1 second, release power.
# Keep holding volume keys.
input "Press Enter when ready..."

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

### MediaTek manual method (BROM mode)
```bash
# 0. Install mtkclient
pip install mtkclient

# 1. Enter BROM mode
# Power off → hold vol up/down → connect USB

# 2. Unlock
mtk da seccfg unlock
```

### Qualcomm manual method (EDL / fastboot)
```bash
# For OEM unlock enabled devices:
adb reboot bootloader
fastboot flashing unlock

# For EDL mode (requires firehose programmer):
pip install edl
edl --loader=prog_ufs_firehose_*.elf unlock
```

### After Unlock
- Phone will factory reset (this is normal)
- Guide user to set up Android
- Enable Developer Options → USB Debugging
- Continue with Workflow E

### Troubleshooting
| Problem | Fix |
|---------|------|
| "No device found" | Install/reinstall driver, check COM port |
| "Connection failed" | Try different USB port, use USB 2.0 |
| SPRD: Phone not detected after screwdriver | Repeat step 1-6, hold vol keys tighter |
| SPRD: miscdata.bin is all zeros | Unlock failed, repeat from step 3 |
| MTK: BROM mode not detected | Install MediaTek DA driver |
| QCOM: EDL mode not detected | Install Qualcomm QDLoader driver |

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

### Magisk v27 (recommended for RMX3760)
```bash
# Built on-device via boot_patch.sh
# Steps:
# 1. Extract Magisk-v27.0.apk on device
# 2. Run boot_patch.sh with KEEPVERITY=false
# 3. Pull new-boot.img
# See: docs/KSU_INIT_BUG.md for details
```

### KernelSU (experimental — KSU-only NOT working on RMX3760)
```bash
python release/build_release.py \
  --kernelsu downloads/kernelsu.ko \
  --stock output/backup/stock_boot_*.img

# Verify
python release/build/verify_release.py
```

### Hybrid Magisk+KernelSU (stable for RMX3760)
```bash
# 1. Flash Magisk v27 boot to both slots (fastboot or dd)
# 2. Install Magisk module ksu_loader_v2.zip via Magisk app
# 3. Module auto-loads kernelsu.ko via ksud late-load at boot
# 4. Install KernelSU Next APK for app root management
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

## Workflow J: Create GitHub Release (Manual — Only After Test Passes)

Use when: user has tested the build artifact on device successfully.

```
1. Go to the successful Actions run on their fork
2. Download RMX3760_KernelSU_Release.zip artifact
3. Flash & test on device (see Workflow G)
4. If everything works:
   a. Go to GitHub → Releases → "Create a new release"
   b. Tag: release-YYYYMMDD (e.g. release-20260522)
   c. Title: "RMX3760 Release YYYYMMDD"
   d. Notes: include vermagic from build output
   e. Upload the tested ZIP as attachment
   f. Publish — do NOT delete old releases
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
| `ksud init no module` | Bug in ksud v3.2.0 | Use hybrid Magisk+KSU instead (see docs/KSU_INIT_BUG.md) |
| `fastboot flash init_boot` fails | "Too many links" error | Use `adb shell dd` with root instead |
| `Magisk v30.7 no su` | ADB shell not granted | Use Magisk v27 which exposes `su -c id` directly |
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
- GitHub Actions workflow: `.github/workflows/release.yml`
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
- **Hybrid recommended**: RMX3760 has init_boot partition. Flash stock boot + patched init_boot for KSU-only,
  but ksud v3.2.0 init binary FAILS to load module (see docs/KSU_INIT_BUG.md). Use hybrid Magisk+KSU instead.
- **Magisk v27 stable, v30.7 NOT recommended**: Magisk v30.7 doesn't expose `su` to ADB shell reliably.
  Magisk v27 provides `su -c id` directly. Download from GitHub releases.
- **Device has init_boot**: `/dev/block/by-name/init_boot_a` (8MB). Stock contains real Android init.
  KSU init_boot can be built with `ksud boot-patch --partition init_boot`.
