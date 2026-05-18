# Realme C53 (RMX3760) — Unlock Bootloader & Root Toolkit

[English](README.md) | **Bahasa Indonesia**

**Bangun kernel module sendiri via GitHub Actions, unlock bootloader, dan root Realme C53 atau tipe Realme lainnya.**

Setiap GitHub Release yang Anda buat di fork sendiri adalah build PRIBADI Anda — simpan dan pakai lagi kapanpun perlu root ulang di device yang sama.

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

1. Buka halaman Releases fork Anda
2. Download `kernelsu.ko` yang sama
3. Backup stock boot baru: `python cli.py` → menu 3
4. Build ulang: `python release/build_release.py --kernelsu kernelsu.ko --stock output/backup/stock_boot_*.img`
5. Flash: `python cli.py` → menu 6

Tidak perlu build kernel module lagi — `.ko` yang sama tetap work selama versi kernel tidak berubah.

---

## 📁 Struktur Repository

```
realme-c53-unlock-root/
├── cli.py                       ← Entry point utama (end-user)
├── src/rmx_unlock/              ← Modul Python (12 file)
├── release/
│   ├── build_release.py         ← Build boot image yang sudah di-patch
│   └── build/
│       ├── verify_release.py    ← Verifikasi SHA256
│       └── host_patch.py        ← Patch boot tanpa HP
├── .github/workflows/
│   ├── build_kernelsu_module.yml ← CI: build kernel module + Release
│   ├── build_release.yml        ← CI: full patched boot image
│   └── test_python.yml          ← CI: unit tests
├── tools/
│   ├── unlock/                  ← Exploit CVE-2022-38694
│   ├── driver/                  ← Driver USB SPRD
│   └── apk/                     ← KernelSU Next APK
└── tests/                       ← Pytest unit tests
```

### Key Design

- **No live patching** — patching boot image dilakukan aman di build stage
- **Test-boot safety** — KernelSU di-test dulu via `fastboot boot` sebelum di-flash
- **Checksum** — SHA256 diverifikasi sebelum flash
- **Release Anda sendiri** — setiap fork produce artifact di GitHub masing-masing
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
