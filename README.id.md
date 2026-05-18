# Realme C53 (RMX3760) — Unlock Bootloader & Root Toolkit

[English](README.md) | **Bahasa Indonesia**

**Unlock bootloader dan root Realme C53 (dan tipe Realme lainnya). Mendukung KernelSU, Magisk, atau hybrid keduanya.**

> ⚠️ **Pengguna RMX3760 (Unisoc T612)**: KSU-only sedang rusak karena bug ksud init.
> **Hybrid Magisk v27 + modul KernelSU via Magisk module** adalah solusi stabil. Lihat [docs/KSU_INIT_BUG.md](docs/KSU_INIT_BUG.md).

Setiap GitHub Release yang Anda buat di fork sendiri adalah build PRIBADI Anda — simpan dan pakai lagi kapanpun perlu root ulang di device yang sama.

---

## 📋 Persyaratan

| Item | Untuk |
|------|-------|
| **Akun GitHub** | Fork + GitHub Actions (build kernel module) |
| **Python 3.10+** | CLI tool (`python cli.py`) |
| **ADB + Fastboot** | Flash & verifikasi (termasuk di Platform Tools) |
| **Kabel USB** | Support transfer data |
| **PC Windows** (atau Linux VM) | Unlock bootloader (spd_dump.exe hanya jalan di Windows) |

Tidak punya Python? Download **Release ZIP** — sudah termasuk flash scripts, tanpa setup.

> 🤖 **Pakai AI assistant?** Lihat [`AI_PROMPT_TEMPLATE.md`](AI_PROMPT_TEMPLATE.md) untuk template prompt siap pakai.
> Rekomendasi: [opencode](https://opencode.ai) — AI agent CLI yang bisa baca/edit file dan
> execute command langsung di terminal. Jalanin dari folder repo ini.

---

## Cara Kerja

```
Fork repo ini
  → Jalankan GitHub Actions (membangun kernelsu.ko UNTUK device Anda)
  → GitHub membuat Release dengan file .ko
  → Download artifact Release
  → Flash ke HP
  → Selesai. Simpan Release untuk masa depan.
```

Tidak perlu setup environment build kernel. Semua berjalan di cloud GitHub.

---

## Dua Cara Pakai

### 🟢 Jalur A — Pakai Release yang Sudah Ada (Tanpa Build)

Jika sudah ada yang build untuk device/kernel yang sama, tinggal download Release-nya:

```
Download kernelsu.ko dari GitHub Release yang sudah ada
  → Taruh di downloads/kernelsu.ko
  → Ikuti "Panduan Cepat" dari Langkah 2
```

Tidak perlu akun GitHub atau fork. Syarat: versi kernel harus cocok (vermagic sama).

### 🔵 Jalur B — Build Sendiri (Direkomendasikan)

Build kernel module pribadi — Release Anda, backup Anda:

```
Fork repo ini → Jalankan GitHub Actions → Dapatkan Release SENDIRI
  → Download kernelsu.ko dari Release Anda
  → Ikuti "Panduan Cepat" dari Langkah 2
```

---

## 📋 Kompatibilitas Device

| Model | SoC | Kernel | Status |
|-------|-----|--------|--------|
| Realme C53 (RMX3760) | Unisoc T612 | 5.15.178-android13-8 | ✅ Teruji |
| Realme lain dengan Unisoc T612 | Unisoc T612 | 5.15.x | ⚠️ Mungkin work (sesuaikan versi kernel) |

Untuk device lain, fork repo dan update versi kernel di `.github/workflows/build_kernelsu_module.yml`.

---

## 🚀 Panduan Cepat (Flow Lengkap)

### Langkah 1 — Fork & Build Kernel Module

1. Fork repo ini ke akun GitHub Anda
2. Buka tab **Actions** → **Build KernelSU LKM** → **Run workflow**
3. Tunggu ~15 menit
4. GitHub membuat **Release** berisi `kernelsu.ko`

### Langkah 2 — Siapkan PC & HP

```bash
# Clone fork Anda
git clone https://github.com/NAMA_ANDA/realme-c53-unlock-root.git
cd realme-c53-unlock-root

# Download Release dari GitHub
#   → Buka halaman Releases fork Anda
#   → Download kernelsu.ko dari release terbaru
#   → Taruh di: downloads/kernelsu.ko

# Install driver SPRD (Windows)
python cli.py       # pilih menu 4
```

### Langkah 3 — Unlock Bootloader

```
python cli.py       # pilih menu 5 (ikuti screwdriver trick)
```

HP akan factory reset. Atur Android, aktifkan USB debugging.

### Langkah 4 — Build & Flash

Pilih metode root Anda:

**Opsi A — Hybrid Magisk + KernelSU (Direkomendasikan untuk RMX3760)**
```bash
# 1. Patch boot stock dengan Magisk v27 di HP via Magisk app
# 2. Flash ke kedua slot:
adb reboot bootloader
fastboot flash boot_a magisk_patched_boot.img
fastboot flash boot_b magisk_patched_boot.img
fastboot reboot

# 3. Install modul Magisk ksu_loader:
#    Push tools/modules/ksu_loader/ksu_loader_v2.zip ke HP
#    Buka Magisk app → Modules → Install from storage → pilih zip
#    Reboot

# 4. Install KernelSU Next APK
adb install tools/apk/KernelSU_Next.apk
```

**Opsi B — KernelSU LKM (Test-boot safety)**
```bash
# Backup stock boot dari HP
python cli.py       # pilih menu 3

# Build boot image KernelSU yang siap flash
python release/build_release.py --kernelsu downloads/kernelsu.ko --stock output/backup/stock_boot_*.img

# Verifikasi artifact
python release/build/verify_release.py

# Flash ke HP (test-boot dulu)
python cli.py       # pilih menu 6
```

### Langkah 5 — Verifikasi Root

```bash
python cli.py       # pilih menu 8
# atau
adb shell su -c id  # harus muncul uid=0(root)
```

---

## 🔄 Pakai Ulang Release Anda

Release GitHub Anda terikat ke fork dan HP Anda. Jika perlu root ulang (setelah OTA, factory reset, dll):

**Root KernelSU:**
1. Buka halaman Releases fork Anda
2. Download `kernelsu.ko` yang sama
3. Backup stock boot baru: `python cli.py` → menu 3
4. Build ulang: `python release/build_release.py --kernelsu kernelsu.ko --stock output/backup/stock_boot_*.img`
5. Flash: `python cli.py` → menu 6

**Hybrid Magisk+KSU:**
1. Patch stock boot baru dengan Magisk v27
2. Install ulang modul ksu_loader
3. Pakai kernelsu.ko dan KernelSU Next APK yang sama

Tidak perlu build kernel module lagi — `.ko` yang sama tetap work selama versi kernel tidak berubah.

---

## 📁 Struktur Repository

```
realme-c53-unlock-root/
├── cli.py                       ← Entry point utama (end-user)
├── AGENTS.md                    ← Instruksi AI agent
├── AI_PROMPT_TEMPLATE.md        ← Template prompt AI siap pakai
├── docs/                        ← Dokumentasi
│   └── KSU_INIT_BUG.md          ← Detail bug ksud init
├── src/rmx_unlock/              ← Python package (semua logic)
├── devices/                     ← Profile device (TOML)
├── release/
│   ├── build_release.py         ← BUILD STAGE: patch stock→release
│   └── build/
│       ├── verify_release.py    ← Verifikasi SHA256
│       └── host_patch.py        ← Patch boot tanpa HP
├── .github/workflows/
│   └── build_kernelsu_module.yml ← CI: build kernel module + Release
├── tools/
│   ├── unlock/
│   │   ├── sprd/              ← Tools SPRD/Unisoc
│   │   ├── mtk/               ← Tools MediaTek
│   │   └── qcom/              ← Tools Qualcomm
│   ├── modules/
│   │   └── ksu_loader/        ← Modul Magisk untuk auto-load KSU
│   ├── driver/                ← Driver USB per chipset
│   └── apk/                   ← KernelSU Next + Magisk APK
└── tests/                       ← Pytest unit tests
```

### Key Design

- **No live patching** — patching boot image dilakukan aman di build stage
- **Test-boot safety** — KernelSU di-test dulu via `fastboot boot` sebelum di-flash
- **Checksum** — SHA256 diverifikasi sebelum flash
- **Release Anda sendiri** — setiap fork produce artifact di GitHub masing-masing
- **Multi-metode root** — KernelSU LKM, Magisk, atau hybrid (Magisk + KSU via Magisk module)
- **Zero Python dependencies** — stdlib only

---

## 🧪 Untuk Developer / Build Kustom

```bash
# Jalankan test
python -m pytest tests/ -v

# Patch boot image tanpa device (Linux x86_64)
python release/build/host_patch.py --kernelsu kernelsu.ko --stock boot.img

# Full build (butuh HP terhubung)
python release/build_release.py --all

# Lint & format
pre-commit run --all-files
```

---

## ⚠️ Peringatan

Unlock bootloader akan **menghapus seluruh data** HP. Backup sebelum melanjutkan.

---

## Kredit

- [TomKing062](https://github.com/TomKing062) — Exploit CVE-2022-38694
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) — KernelSU Next
- [topjohnwu](https://github.com/topjohnwu/Magisk) — Magisk
- Realme Open Source

## Lisensi

Tujuan edukasi. Gunakan dengan risiko sendiri.
