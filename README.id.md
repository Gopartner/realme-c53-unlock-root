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

```
./scripts/backup.sh
```

Perintah ini akan menyimpan file media (DCIM, Pictures, Download, dll) dan mendump stock boot image.

### 2. Install Driver SPRD

Install driver dari `tools/driver/SPD_Driver_R4.20.4201.zip` sebelum unlock.

### 3. Masuk Mode SPRD U2S Diag

1. Matikan HP
2. Buka casing belakang, cari test point di motherboard
3. Hubungkan test point ke ground dengan obeng/pin
4. Colok kabel USB ke PC — HP akan terdeteksi sebagai **SPRD U2S Diag (COM3)**

### 4. Unlock Bootloader

Semua alat ada di `tools/unlock/`. Jalankan script unlock:

```
./scripts/unlock.sh
```

Proses yang akan berjalan:
1. Dump partisi bootchain (PGPT, SPL, uboot)
2. Generate SPL yang sudah di-patch via `gen_spl-unlock.exe`
3. Erase SPL dan write cboot
4. **Tunggu Anda melakukan screwdriver trick** (tahan kedua tombol volume + tap power)
5. Jalankan payload unlock (`spl-unlock.bin`)
6. **Screwdriver trick lagi**
7. Restore original SPL dan uboot
8. Wipe partisi misc (bootloader sekarang tidak terkunci)

Verifikasi: `miscdata.bin` berisi data non-zero.

### 5. Backup Stock Boot Image

Setelah HP reboot (factory reset), atur Android dan aktifkan USB debugging:

```
./scripts/backup.sh
```

Atau manual:
```
adb shell dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.img
adb pull /data/local/tmp/boot.img stock_boot.img
```

### 6. Root dengan Magisk (direkomendasikan)

```
./scripts/root_magisk.sh
```

Script akan:
1. Install aplikasi Magisk di HP
2. Ekstrak file Magisk dari APK
3. Push stock boot + file Magisk ke HP
4. Patch boot image dengan Magisk (membuat ramdisk baru dengan magiskinit)
5. Flash boot yang sudah di-patch ke `boot_a` dan `boot_b`
6. Reboot

Setelah reboot, buka **Magisk** → **Superuser** → Grant root ke **Shell**.

```
adb shell su -c id
# -> uid=0(root)
```

### 7. Root dengan KernelSU (LKM)

Perlu membangun `kernelsu.ko` dari source kernel (lihat `scripts/root_kernelsu.sh`).

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
