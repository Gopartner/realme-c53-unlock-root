# Realme C53 (RMX3760) — Unlock Bootloader & Root Toolkit

[![English](README.md)](#) | **Bahasa Indonesia**

Toolkit untuk unlock bootloader (CVE-2022-38694) dan root Realme C53 / RMX3760 (Unisoc T612).

---

## 📋 Spesifikasi

| Item | Detail |
|------|--------|
| Model | Realme C53 (RMX3760) |
| SoC | Unisoc T612 (ums9230) |
| Kernel | `5.15.178-android13-8` |
| Android | 15 (AP3A.240905.015.A2) |
| Slot | A/B (`boot_a`/`boot_b`) |

---

## 🏗️ Untuk Developer

Membangun release image yang siap di-flash dari stock boot:

```bash
# 1. Backup stock boot (perlu HP sudah USB debugging)
python cli.py        # pilih menu 3

# 2. Build release image
python release/build_release.py --kernelsu kernelsu.ko --stock output/backup/stock_boot_*.img
python release/build_release.py --magisk tools/apk/Magisk-v30.7.apk --stock output/backup/stock_boot_*.img
python release/build_release.py --all   # build semua

# 3. Verifikasi artifact
python release/build/verify_release.py
```

**Output:** `release/runtime/` + `metadata.txt` (SHA256).

### KernelSU LKM Build

Build `kernelsu.ko` via GitHub Actions:
```
https://github.com/Gopartner/realme-c53-unlock-root/actions
```
Lihat `AGENTS.md` untuk detail vermagic.

---

## 🛠️ Untuk End-User

### Persiapan

- Windows (atau OS dengan ADB/fastboot)
- Kabel USB data
- Driver SPRD — `tools/driver/`

### Jalankan CLI

```bash
python cli.py
```

| Menu | Fungsi |
|------|--------|
| 1 | Cek environment (adb/fastboot) |
| 2 | Validasi device (RMX3760) |
| 3 | Backup stock boot image |
| 4 | Install driver SPRD (buka folder) |
| 5 | **Unlock bootloader** (CVE-2022-38694) |
| 6 | **Flash KernelSU** (test-boot dulu) |
| 7 | **Flash Magisk** |
| 8 | Verify root (`su -c id`) |
| 9 | Lihat metadata release |

### Alur lengkap

```
1. Install driver        → menu 4
2. Unlock bootloader     → menu 5 + screwdriver trick
3. Backup stock boot     → menu 3
4. Build release (dev)   → python release/build_release.py --all
5. Flash root            → menu 6 (KSU) atau 7 (Magisk)
6. Verify root           → menu 8
```

---

## 📁 Struktur Repository

```
realme-c53-unlock-root/
├── cli.py                       ← Entry point (end-user)
├── src/rmx_unlock/              ← Semua logika (12 modul)
│   ├── config.py                ← Paths & constants
│   ├── adb.py                   ← ADB/Fastboot wrapper
│   ├── flash.py                 ← Flashing dengan safety
│   ├── unlock.py                ← CVE-2022-38694 unlock
│   ├── backup.py                ← Backup boot image
│   ├── validation.py            ← Env/device/checksum
│   ├── metadata.py              ← Release metadata parser
│   ├── logger.py                ← Session logging
│   ├── driver.py                ← Driver installer
│   └── cli.py                   ← Menu orchestrator
├── release/
│   ├── build_release.py         ← Build stage (developer)
│   └── build/verify_release.py  ← Verifikasi artifact
├── tools/
│   ├── unlock/                  ← CVE-2022-38694 tool
│   ├── driver/                  ← SPRD driver
│   └── apk/                     ← APK files
└── output/backup/               ← Stock boot backups
```

### Key Design

- **No live patching** — semua patching di build stage, aman untuk end-user
- **Test-boot safety** — KernelSU di-test dulu via `fastboot boot` sebelum di-flash
- **Checksum** — SHA256 diverifikasi sebelum flashing
- **Python stdlib only** — zero dependencies

---

## ⚠️ Peringatan

Unlock bootloader akan **menghapus seluruh data** HP. Backup sebelum unlock.

---

## Kredit

- [TomKing062](https://github.com/TomKing062) — CVE-2022-38694
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next)
- [topjohnwu](https://github.com/topjohnwu/Magisk)
- Realme Open Source

## Lisensi

Edukasi. Gunakan dengan risiko sendiri.
