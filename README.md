# Realme C53 (RMX3760) — Bootloader Unlock & Root Toolkit

[**English**](#) | [Bahasa Indonesia](README.id.md)

Toolkit to unlock bootloader (CVE-2022-38694) and root Realme C53 / RMX3760 (Unisoc T612).

---

## 📋 Device Specs

| Item | Detail |
|------|--------|
| Model | Realme C53 (RMX3760) |
| SoC | Unisoc T612 (ums9230) |
| Kernel | `5.15.178-android13-8` |
| Android | 15 (AP3A.240905.015.A2) |
| Slots | A/B (`boot_a`/`boot_b`) |

---

## 🏗️ For Developers

Build flashable release images from stock boot:

```bash
# 1. Backup stock boot (requires USB debugging)
python cli.py        # select menu 3

# 2. Build release image
python release/build_release.py --kernelsu kernelsu.ko --stock output/backup/stock_boot_*.img
python release/build_release.py --magisk tools/apk/Magisk-v30.7.apk --stock output/backup/stock_boot_*.img
python release/build_release.py --all   # build all

# 3. Verify artifacts
python release/build/verify_release.py
```

**Output:** `release/runtime/` + `metadata.txt` (SHA256 checksums).

### KernelSU LKM Build

Build `kernelsu.ko` via GitHub Actions:
```
https://github.com/Gopartner/realme-c53-unlock-root/actions
```
See `AGENTS.md` for vermagic details.

---

## 🛠️ For End-Users

### Prerequisites

- Windows (or any OS with ADB/fastboot)
- USB data cable
- SPRD driver — `tools/driver/`

### Run the CLI

```bash
python cli.py
```

| Menu | Function |
|------|----------|
| 1 | Check environment (adb/fastboot) |
| 2 | Validate device (RMX3760) |
| 3 | Backup stock boot image |
| 4 | Install SPRD driver (open folder) |
| 5 | **Unlock bootloader** (CVE-2022-38694) |
| 6 | **Flash KernelSU** (test-boot first) |
| 7 | **Flash Magisk** |
| 8 | Verify root (`su -c id`) |
| 9 | Show release metadata |

### Full workflow

```
1. Install driver        → menu 4
2. Unlock bootloader     → menu 5 + screwdriver trick
3. Backup stock boot     → menu 3
4. Build release (dev)   → python release/build_release.py --all
5. Flash root            → menu 6 (KSU) or 7 (Magisk)
6. Verify root           → menu 8
```

---

## 📁 Repository Structure

```
realme-c53-unlock-root/
├── cli.py                       ← Entry point (end-user)
├── src/rmx_unlock/              ← All logic (12 modules)
│   ├── config.py                ← Paths & constants
│   ├── adb.py                   ← ADB/Fastboot wrapper
│   ├── flash.py                 ← Flashing with safety
│   ├── unlock.py                ← CVE-2022-38694 unlock
│   ├── backup.py                ← Boot image backup
│   ├── validation.py            ← Env/device/checksum
│   ├── metadata.py              ← Release metadata parser
│   ├── logger.py                ← Session logging
│   ├── driver.py                ← Driver installer
│   └── cli.py                   ← Menu orchestrator
├── release/
│   ├── build_release.py         ← Build stage (developer)
│   └── build/verify_release.py  ← Artifact verification
├── tools/
│   ├── unlock/                  ← CVE-2022-38694 tool
│   ├── driver/                  ← SPRD driver
│   └── apk/                     ← APK files
└── output/backup/               ← Stock boot backups
```

### Key Design

- **No live patching** — all patching happens in build stage, safe for end-users
- **Test-boot safety** — KernelSU tested via `fastboot boot` before flashing
- **Checksum** — SHA256 verified before every flash
- **Python stdlib only** — zero dependencies

---

## ⚠️ Warning

Unlocking bootloader **wipes all device data**. Backup before proceeding.

---

## Credits

- [TomKing062](https://github.com/TomKing062) — CVE-2022-38694
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next)
- [topjohnwu](https://github.com/topjohnwu/Magisk)
- Realme Open Source

## License

Educational purposes only. Use at your own risk.
