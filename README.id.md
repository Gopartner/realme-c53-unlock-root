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
- Driver SPRD USB (untuk proses unlock)
- Waktu ~30 menit

## Metode Root

Panduan ini mencakup **dua** metode root:

1. **Magisk** (direkomendasikan, lebih mudah) — Bekerja melalui patching init ramdisk
2. **KernelSU** (mode LKM) — Perlu membangun kernel module dari source

## Panduan Cepat

### 1. Backup Data

**PERINGATAN:** Unlock bootloader akan **menghapus seluruh data** di HP.
Backup data penting Anda sebelum melanjutkan.

Gunakan `scripts/backup.sh` untuk membackup file media dan stock boot image.

### 2. Unlock Bootloader

Gunakan exploit [CVE-2022-38694](https://github.com/TomKing062/CVE-2022-38694_unlock_bootloader)
oleh TomKing062.

1. Install driver SPRD (ada di folder `sprd_driver/`)
2. Matikan HP
3. Hubungkan pin motherboard untuk masuk mode SPRD U2S Diag
4. Jalankan prosedur unlock (lihat `scripts/unlock.sh`)

### 3. Backup Stock Boot Image

```
adb shell dd if=/dev/block/by-name/boot_a of=/data/local/tmp/boot.img
adb pull /data/local/tmp/boot.img stock_boot.img
```

### 4. Root dengan Magisk

```
# Push file Magisk ke HP
adb push stock_boot.img /data/local/tmp/
adb shell /data/local/tmp/magisk/boot_patch.sh /data/local/tmp/boot.img
adb pull /data/local/tmp/magisk/new-boot.img magisk_patched_boot.img

# Flash
adb reboot bootloader
fastboot flash boot_a magisk_patched_boot.img
fastboot flash boot_b magisk_patched_boot.img
fastboot reboot
```

Buka aplikasi Magisk → Superuser → Grant root ke Shell.

### 5. Root dengan KernelSU (LKM)

Perlu membangun `kernelsu.ko` dari source kernel yang cocok dengan vermagic perangkat.

```
git clone <url_source_kernel>
cd kernel_source
curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/main/kernel/setup.sh" | bash -
make ARCH=arm64 CC=clang LLVM=1 modules_prepare
make ARCH=arm64 CC=clang LLVM=1 M=KernelSU modules
```

Gunakan `ksud` untuk patch boot image dengan file .ko yang dihasilkan.
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
