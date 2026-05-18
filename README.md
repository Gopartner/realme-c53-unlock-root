# Realme C53 (RMX3760) — Bootloader Unlock & Root Toolkit

[**English**](#) | [Bahasa Indonesia](README.id.md)

**Build your own KernelSU module via GitHub Actions, unlock bootloader, and root your Realme C53 or other Realme devices.**

Every GitHub release you create on your own fork is YOUR personal build — save it and reuse it anytime you need to root again on the same device.

---

## 📋 Requirements

| Item | Needed For |
|------|-----------|
| **GitHub account** | Fork + GitHub Actions (build kernel module) |
| **Python 3.10+** | CLI tool (`python cli.py`) |
| **ADB + Fastboot** | Flash & verify (included with Platform Tools) |
| **USB cable** | Data transfer capable |
| **Windows PC** (or Linux VM) | Bootloader unlock (spd_dump.exe only runs on Windows) |

Don't have Python? Download the **Release ZIP** instead — it includes flash scripts and requires zero setup.

> 🤖 **Use an AI assistant?** See [`AI_PROMPT_TEMPLATE.md`](AI_PROMPT_TEMPLATE.md) for ready-to-use prompts.
> Recommended: [opencode](https://opencode.ai) — AI agent CLI that can read/edit files and
> run commands directly in your terminal. Run it from this repo folder.

---

## How It Works

```
You fork this repo
  → Run GitHub Actions (builds kernelsu.ko for YOUR device)
  → GitHub creates a Release with the .ko file
  → Download the Release artifact
  → Flash to your phone
  → Done. Keep the Release for future use.
```

No need to set up a kernel build environment. Everything runs in GitHub's cloud.

---

## Two Ways to Use

### 🟢 Path A — Use an Existing Release (No Build)

If someone has already built for the same device/kernel, just download their Release:

```
Download kernelsu.ko from an existing GitHub Release
  → Place it in downloads/kernelsu.ko
  → Follow "Quick Start" from Step 2
```

No GitHub account or fork needed. Only prerequisite: matching kernel version (vermagic).

### 🔵 Path B — Build Your Own (Recommended)

Build your own personal kernel module — your Release, your backup:

```
Fork this repo → Run GitHub Actions → Get YOUR Release
  → Download kernelsu.ko from your own Release
  → Follow "Quick Start" from Step 2
```

---

## 📋 Device Compatibility

| Model | SoC | Kernel | Status |
|-------|-----|--------|--------|
| Realme C53 (RMX3760) | Unisoc T612 | 5.15.178-android13-8 | ✅ Tested |
| Other Unisoc T612 devices | Unisoc T612 | 5.15.x | ⚠️ May work (adjust kernel version) |

For other devices, fork the repo and update the kernel version in `.github/workflows/build_kernelsu_module.yml`.

---

## 🚀 Quick Start (Full Flow)

### Step 1 — Fork & Build Kernel Module

1. Fork this repo to your GitHub account
2. Go to **Actions** tab → **Build & Create Complete Release** → **Run workflow**
3. Wait ~15 minutes
4. GitHub creates a **Release** with `kernelsu.ko` inside

### Step 2 — Prepare PC & Phone

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/realme-c53-unlock-root.git
cd realme-c53-unlock-root

# Download the Release from GitHub
#   → Go to your fork's Releases page
#   → Download kernelsu.ko from the latest release
#   → Place it in: downloads/kernelsu.ko

# Install SPRD driver (Windows only)
python cli.py       # select menu 4
```

### Step 3 — Unlock Bootloader

```
python cli.py       # select menu 5 (follow the screwdriver trick)
```

Phone will factory reset. Set up Android, enable USB debugging.

### Step 4 — Build & Flash

```bash
# Backup stock boot from your phone
python cli.py       # select menu 3

# Build flashable KernelSU boot image
python release/build_release.py --kernelsu downloads/kernelsu.ko --stock output/backup/stock_boot_*.img

# Verify the artifact
python release/build/verify_release.py

# Flash to phone (test-boot first)
python cli.py       # select menu 6
```

### Step 5 — Verify Root

```bash
python cli.py       # select menu 8
# or
adb shell su -c id  # should show uid=0(root)
```

---

## 🔄 Reusing Your Release

Your GitHub Release is tied to your fork and your phone. If you ever need to root again (after OTA update, factory reset, etc.):

1. Go to your fork's Releases page
2. Download the same `kernelsu.ko`
3. Backup fresh stock boot: `python cli.py` → menu 3
4. Rebuild: `python release/build_release.py --kernelsu kernelsu.ko --stock output/backup/stock_boot_*.img`
5. Flash: `python cli.py` → menu 6

No need to rebuild the kernel module — the same `.ko` works as long as the kernel version hasn't changed.

---

## 📁 Repository Structure

```
realme-c53-unlock-root/
├── cli.py                       ← Thin entry point (end-user)
├── AGENTS.md                    ← AI agent instructions (10 workflows)
├── AI_PROMPT_TEMPLATE.md        ← Copy-paste prompts for any AI
├── pyproject.toml               ← Package metadata & tool config
├── src/rmx_unlock/              ← Python package (13 modules)
├── release/
│   ├── build_release.py         ← Build patched boot image
│   ├── runtime/                 ← Release artifacts (gitignored)
│   │   ├── metadata.txt         ← SHA256 checksums
│   │   └── kernelsu_patched_boot.img
│   └── build/
│       ├── flash.bat            ← One-click flash script
│       ├── verify_release.py    ← SHA256 verification
│       └── host_patch.py        ← Patch boot without phone
├── .github/workflows/
│   ├── build_kernelsu_module.yml ← CI: build module + Release
│   └── test_python.yml          ← CI: pytest on push/PR
├── tools/
│   ├── unlock/                  ← CVE-2022-38694 exploit
│   ├── driver/                  ← SPRD USB driver
│   └── apk/                     ← KernelSU Next + Magisk APKs
├── tests/                       ← Pytest unit tests
├── output/                      ← Backups & logs (gitignored)
│   ├── backup/                  ← Stock boot images
│   └── logs/                    ← Session logs
├── downloads/                   ← User-provided kernelsu.ko
├── files/                       ← Reference data (partition layout)
├── kernel_ack_5.15/             ← ACK kernel source (local build)
├── kernel_source/               ← Realme GPL source (5.4, reference)
└── toolchain/                   ← Build toolchain (optional)
```

### Key Design

- **No live patching** — boot image patching is done safely in the build stage
- **Test-boot safety** — KernelSU tested via `fastboot boot` before flashing
- **Checksum verification** — SHA256 checked before every flash
- **Your own Release** — each fork produces its own artifacts on its own GitHub
- **Zero Python dependencies** — stdlib only

---

## 🧪 For Developers / Custom Builds

```bash
# Run tests
python -m pytest tests/ -v

# Patch boot image without a device (Linux x86_64)
python release/build/host_patch.py --kernelsu kernelsu.ko --stock boot.img

# Full build (requires phone connected)
python release/build_release.py --all

# Lint & format
pre-commit run --all-files
```

---

## ⚠️ Warning

Unlocking the bootloader **wipes all device data**. Backup before proceeding.

---

## Credits

- [TomKing062](https://github.com/TomKing062) — CVE-2022-38694 unlock exploit
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) — KernelSU Next
- [topjohnwu](https://github.com/topjohnwu/Magisk) — Magisk
- Realme Open Source — Kernel source code

## License

Educational purposes only. Use at your own risk.
