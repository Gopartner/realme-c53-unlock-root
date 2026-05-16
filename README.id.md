# Realme C53 (RMX3760) — Panduan Unlock Bootloader & Root

Panduan lengkap untuk membuka kunci bootloader (via CVE-2022-38694) dan
mendapatkan akses root di Realme C53 / RMX3760 (Unisoc T612).

## Spesifikasi Perangkat

| Spesifikasi | Nilai |
|-------------|-------|
| Model | Realme C53 (RMX3760) |
| SoC | Unisoc T612 (ums9230_hulk) |
| CPU | 2x Cortex-A75 + 6x Cortex-A55 |
| RAM | 8 GB |
| Penyimpanan | 256 GB |
| Layar | 720x1600 HD+, 320 dpi |
| Kernel | 5.15.178-android13-8 |
| Android | 15 (SDK 35) |
| Arsitektur | arm64-v8a |
| Pabrikan | realme |
| Build | AP3A.240905.015.A2 |
| Slot | A/B (boot_a/boot_b, init_boot_a/init_boot_b) |

## Persyaratan

- PC Windows (atau OS lain dengan ADB/fastboot)
- Kabel USB (mendukung transfer data)
- Driver SPRD USB — sudah termasuk di `tools/driver/`
- Waktu ~30 menit

## Isi Repository

```
realme-c53-unlock-root/
├── README.md                    # Panduan Bahasa Inggris
├── README.id.md                 # Panduan Bahasa Indonesia
├── AGENTS.md                    # Referensi untuk AI agent
├── scripts/
│   ├── backup.sh                # Backup data sebelum unlock
│   ├── unlock.sh                # Prosedur unlock bootloader
│   ├── root_magisk.sh           # Root dengan Magisk
│   └── root_kernelsu.sh         # Root dengan KernelSU LKM
├── tools/
│   ├── unlock/                  # Tool unlock CVE-2022-38694 (spd_dump, dll)
│   ├── driver/                  # Driver SPRD USB untuk Windows
│   └── apk/                     # Aplikasi Magisk & KernelSU Next
├── images/
│   └── stock_boot.img           # File boot asli (64 MB)
└── files/
    └── partition_layout.txt     # Tabel partisi
```

Semua alat dan file sudah tersedia — tidak perlu download apapun lagi.

## Metode Root

Panduan ini mencakup **dua** metode root:

1. **Magisk** (direkomendasikan, lebih mudah) — Bekerja melalui patching init ramdisk
2. **KernelSU** (mode LKM) — Perlu membangun kernel module dari source

## Panduan Cepat

### 1. Backup Data

**PERINGATAN:** Unlock bootloader akan **menghapus seluruh data** di HP.
Backup data penting Anda sebelum melanjutkan.

Jalankan `scripts/backup.sh` atau manual:
```
adb shell cp -r /sdcard/DCIM /sdcard/Download /sdcard/Pictures /sdcard/backup/
adb pull /sdcard/backup/ ./backup/
```

### 2. Install Driver SPRD

Install driver dari `tools/driver/SPD_Driver_R4.20.4201.zip` sebelum unlock.

### 3. Unlock Bootloader

Menggunakan exploit [CVE-2022-38694](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader)
oleh TomKing062. Semua file ada di `tools/unlock/`.

1. Install driver SPRD (`tools/driver/`)
2. Matikan HP
3. Hubungkan pin motherboard untuk masuk mode SPRD U2S Diag (COM3)
4. Jalankan prosedur unlock (lihat `scripts/unlock.sh`)

### 4. Backup Stock Boot Image (jika tidak pakai yang sudah disediakan)

Stock boot image sudah tersedia di `images/stock_boot.img`.
Untuk dump sendiri (perangkat dan build yang sama):
```
adb shell dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.img
adb pull /data/local/tmp/boot.img stock_boot.img
```

### 5. Root dengan Magisk

```
# Install aplikasi Magisk di HP
adb install tools/apk/Magisk-v30.7.apk

# Push stock boot ke HP
adb push images/stock_boot.img /data/local/tmp/boot.img

# Extract file Magisk lalu patch
# (Lihat scripts/root_magisk.sh untuk langkah lengkap)

# Flash boot yang sudah di-patch
adb reboot bootloader
fastboot flash boot_a magisk_patched_boot.img
fastboot flash boot_b magisk_patched_boot.img
fastboot reboot
```

Buka aplikasi Magisk → Superuser → Grant root ke Shell.

### 6. Root dengan KernelSU (LKM)

Perlu membangun `kernelsu.ko` dari source kernel yang cocok.

```
# Install aplikasi KernelSU Next
adb install tools/apk/KernelSU_Next.apk

# Bangun kernel module dari source, lalu:
adb shell /data/local/tmp/ksud boot-patch \
    -b /data/local/tmp/boot.img \
    -m /data/local/tmp/kernelsu.ko \
    --magiskboot /data/local/tmp/magiskboot \
    -o /data/local/tmp/ --out-name kernelsu_patched_boot.img
```

Lihat `scripts/root_kernelsu.sh` untuk detail.

## Layout Partisi

| Partisi | Ukuran | Deskripsi |
|---------|--------|-----------|
| boot_a/boot_b | 64 MB | Kernel + DTB (tanpa ramdisk) |
| init_boot_a/b | 8 MB | Ramdisk (skrip init) |
| vendor_boot | 100 MB | Vendor ramdisk |
| super | 8000 MB | System, product, vendor |
| userdata | sisanya | Data pengguna |
| miscdata | 1 MB | Flag unlock bootloader |

Detail lengkap di `files/partition_layout.txt`.

## Source Kernel

```
https://github.com/realme-kernel-opensource/realme_C51_C53_Note50_C60_C51_N53-AndroidU-kernel-source
```

Catatan: Berisi file `aux.c` dan `aux.h` yang merupakan nama file terlarang
di Windows. Gunakan WSL/Linux untuk clone.

## Kredit

- [TomKing062](https://github.com/TomKing062) — Exploit CVE-2022-38694
- [KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next) — KernelSU Next
- [topjohnwu](https://github.com/topjohnwu/Magisk) — Magisk
- Realme Open Source — Source code kernel
- [opencode](https://opencode.ai) — Agen AI coding yang membantu proses unlock bootloader, root, dan dokumentasi
- opencode/big-pickle — Model yang menjalankan agen AI

## Lisensi

Dokumentasi ini disediakan untuk tujuan edukasi.
Gunakan dengan risiko Anda sendiri.
