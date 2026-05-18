# 📋 AI Prompt Templates — Realme C53 Unlock & Root

Bingung mau nulis apa ke AI agent? Copy-paste aja template di bawah.

> **Prasyarat**: kamu sudah clone repo ini dan buka AI agent (opencode, Cline, Claude, dll)
> dari **dalam folder repo**. Biar AI bisa baca file-file nya.

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

## 6. Error / trouble

```
Saya gagal di step [sebutkan]. Ini error nya:

[paste error message]

Saya pakai Realme C53 (RMX3760). Tolong diagnose.
Lihat AGENTS.md bagian Troubleshooting.
```

---

## Tips

- Jalankan AI agent dari folder repo ini (`cd realme-c53-unlock-root`)
- Kasih prompt yang jelas — mau root total, atau cuma unlock, atau cuma build
- Kalau error — paste mentahan error message nya
- Setiap langkah, kamu harus konfirmasi dulu sebelum AI lanjut

---

## Lisensi

Bebas pakai.
