# 📋 AI Prompt Templates — Realme C53 Unlock & Root

Bingung mau nulis apa ke AI agent? Copy-paste aja template di bawah.

> **Prasyarat**: kamu sudah clone repo ini dan buka AI agent (opencode, Cline, Claude, dll)
> dari **dalam folder repo**. Biar AI bisa baca file-file nya.
>
> **Multi-device + Multi-chipset**: Ganti `RMX3760` sesuai device kamu (atau ganti
> `Realme C53`). Profile tersedia di `devices/` — SPRD (C53/C51), MediaTek, Qualcomm.
> Kalau device kamu belum ada, bilang ke AI "bikin profile baru".

---

## 1. Root lengkap — dari awal sampai flashing

```
Saya mau root Realme C53 (RMX3760) dari awal sampai selesai.

Windows 10, Python sudah terinstall, USB siap, punya akun GitHub.

Baca AGENTS.md dan pandu saya step by step. Tunggu konfirmasi saya
sebelum lanjut ke step berikutnya.
```

---

## 2. Root ulang — pakai release lama

```
Saya pernah root Realme C53 (RMX3760) sebelumnya.
Saya masih punya kernelsu.ko dari Release GitHub yang lama.
HP sudah USB debugging.

Saya perlu root ulang. Pandu saya tanpa build ulang kernel module.
```

---

## 3. Unlock bootloader doang

```
Saya cuma perlu unlock bootloader Realme C53 (RMX3760).
HP sudah masuk SPRD U2S Diag mode (COM3) dan driver sudah terinstall.

Pandu saya step by step unlock via CVE-2022-38694.
Jangan lupa kasih tau kapan screwdriver trick.
```

---

## 4. Build kernel module (GitHub Actions)

```
Saya ingin build kernelsu.ko untuk Realme C53 (RMX3760).
Kernel: 5.15.178-android13-8. Saya punya akun GitHub.

Pandu saya: fork repo → trigger GitHub Actions → download hasil Release.
```

---

## 5. Build + publish release untuk orang lain

```
Saya sudah berhasil root Realme C53 (RMX3760). Semua file sudah siap:
- kernelsu.ko (dari GitHub Actions)
- Stock boot image (backup)
- Patched boot image (sudah di build)

Sekarang saya mau publish sebagai GitHub Release biar bisa dipakai
orang lain. Pandu saya.
```

---

## 6. Backup full — dari BROM mode (sebelum operasi)

Gunakan kalau HP sudah masuk **BROM / download mode** via kabel USB.
Backup ini penting sebagai jaring pengaman kalau operasi gagal, dan
sebagai bahan referensi riset kernel / unlock.

```
HP saya Realme C53 (RMX3760) sudah masuk BROM / download mode
dan terdeteksi di laptop (port USB).

Saya mau backup semua partisi system penting sebelum melakukan
operasi unlock atau flashing apapun. Saya butuh file-file ini untuk:
1. Pemulihan jika operasi gagal
2. Referensi riset unlock / build kernel

Pandu saya: dump partisi boot, super, vendor, dtbo, vbmeta, persist,
dan partisi penting lainnya. Simpan di folder output/backup/.
Jelaskan fungsi setiap partisi yang di backup.
```

---

## 7. Error / trouble

```
Saya gagal di step [sebutkan]. Ini error nya:

[paste error message]

Saya pakai Realme C53 (RMX3760). Tolong diagnose.
Lihat AGENTS.md bagian Troubleshooting.
```

---

## 8. Cek status device + environment PC

Gunakan untuk ngecek kondisi HP sebelum operasi (butuh USB debugging aktif)
dan memastikan PC/laptop siap.

```
HP saya Realme C53 (RMX3760), USB debugging aktif, terhubung ke PC.

Saya mau cek semuanya:

— CEK PC / LAPTOP —
1. Python — sudah terinstall? Versi minimal 3.10?
2. ADB & Fastboot — sudah ada di PATH?
3. Git — sudah terinstall?
4. Folder output/backup/ — ada ruang kosong?

— CEK HP —
5. Bootloader — locked atau unlocked?
6. Status AVB / vbmeta — apakah verified boot aktif?
7. Mode SELinux — enforcing atau permissive?
8. Partisi — ada berapa slot (A/B)? Ukuran boot, super, vbmeta?
9. Kernel — versi dan vermagic nya?
10. Root — sudah ada akses root atau belum?

Tampilkan semua informasinya. Jelaskan apa artinya masing-masing.
```

---

## Tips

- Jalankan AI agent dari folder repo ini (`cd realme-c53-unlock-root`)
- Kasih prompt yang jelas — mau root total, atau cuma unlock, atau cuma build
- Kalau error — paste mentahan error message nya
- Setiap langkah, kamu harus konfirmasi dulu sebelum AI lanjut
- **Untuk AI agent**: Baca AGENTS.md dulu. Jangan pernah janjiin fitur yang
  tidak ada di repo ini. Kalau user minta sesuatu di luar scope, bilang
  jujur dan kasih alternatif yang realistis.

---

## Lisensi

Bebas pakai.
