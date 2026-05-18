# 🤖 AI Prompt Templates — Realme C53 Unlock & Root

Copy-paste template di bawah ke AI agent favorit Anda untuk mendapatkan bantuan
yang akurat sesuai project ini.

> **Rekomendasi**: [opencode](https://opencode.ai) — AI agent CLI khusus coding.
> Bisa baca, edit, dan execute command langsung di terminal.

Prasyarat: **Anda sudah clone repo ini** dan menjalankan AI agent dari **dalam folder repo**.
Semua workflow lengkap ada di `AGENTS.md`.

---

## 📋 Template 1: Root Lengkap (Dari Awal Sampai Selesai)

**Copy ini ke AI agent:**

```
Saya sudah clone repo ini dan ingin root Realme C53 (RMX3760) dari awal sampai selesai.

Lingkungan:
- Windows 10/11
- Python sudah terinstall
- USB cable siap
- Saya sudah punya akun GitHub

Saya sudah di dalam folder repo ini. Jalanin step by step.

Yang perlu dilakukan:
1. Cek environment saya (Python, ADB, fastboot, git)
2. Pandu saya fork repo ini ke GitHub saya (saya buka browser)
3. Trigger GitHub Actions build kernel module (saya buka browser)
4. Sambil nunggu build selesai, install SPRD driver
5. Unlock bootloader via CVE-2022-38694
6. Setelah unlock, set up HP + enable USB debugging
7. Backup stock boot image
8. Download kernelsu.ko dari Release GitHub
9. Build patched boot image
10. Flash KernelSU (test-boot dulu)
11. Verify root

Baca AGENTS.md dan pandu saya langkah demi langkah.
Jangan lanjut ke step berikutnya sebelum saya konfirmasi.
```

---

## 📋 Template 2: Hanya Unlock Bootloader

**Copy ini ke AI agent:**

```
Saya sudah punya akses ke repo ini dan hanya perlu unlock bootloader
Realme C53 (RMX3760) via CVE-2022-38694.

Device sudah di SPRD U2S Diag mode (COM3).
Driver SPRD sudah terinstall.

Tolong pandu saya step by step unlock bootloader sesuai AGENTS.md Workflow D.
Jangan lupa kasih tau kapan harus lakukan screwdriver trick.
```

---

## 📋 Template 3: Build Kernel Module (GitHub Actions)

**Copy ini ke AI agent:**

```
Saya ingin build kernel module (kernelsu.ko) untuk Realme C53 (RMX3760)
via GitHub Actions. Kernel: 5.15.178-android13-8.

Saya sudah punya akun GitHub dan sudah clone repo ini.

Tolong:
1. Buka browser dan pandu saya fork repo ini
2. Trigger GitHub Actions workflow "Build & Create Complete Release"
3. Download hasil Release setelah selesai

Baca AGENTS.md Workflow A untuk detailnya.
```

---

## 📋 Template 4: Build Release + Release ke Publik

**Copy ini ke AI agent setelah berhasil root:**

```
Saya sudah berhasil unlock dan root Realme C53 (RMX3760).
Sekarang saya ingin membuat GitHub Release yang bisa dipakai orang lain.

Yang sudah saya punya:
- kernelsu.ko (sudah build via GitHub Actions)
- Stock boot image (sudah backup)
- Patched boot image (sudah build)

Tolong bantu saya:
1. Verifikasi semua artifact (SHA256)
2. Buat GitHub Release di fork saya
3. Kasih tau cara orang lain pakai Release ini

Baca AGENTS.md Workflow J untuk detailnya.
```

---

## 📋 Template 5: Troubleshooting / Error

**Copy ini ke AI agent:**

```
Saya mengalami masalah saat [sebutkan masalahnya, misal: unlock bootloader gagal /
flash boot error / vermagic mismatch / device not detected].

Saya pakai Realme C53 (RMX3760) dan sudah clone repo ini.

Error message:
[paste error message di sini]

Tolong bantu diagnose dan kasih solusi. Lihat AGENTS.md bagian Troubleshooting.
```

---

## 📋 Template 6: Root Ulang (Pakai Release Lama)

**Copy ini ke AI agent:**

```
Saya sudah pernah root Realme C53 (RMX3760) sebelumnya dan punya
Release ZIP dari GitHub fork saya.

Saya perlu root ulang karena [OTA update / factory reset / ganti ROM].

Yang saya punya:
- kernelsu.ko dari Release sebelumnya
- HP sudah USB debugging

Tolong bantu root ulang tanpa build kernel module lagi.
Lihat AGENTS.md bagian "Reusing Your Release".
```

---

## Tips Penggunaan

1. **Jalankan AI agent dari folder repo ini** — biar AI bisa baca struktur file dan execute command
2. **Sebutkan model HP dengan benar** — `Realme C53 (RMX3760)`
3. **Copy error message lengkap** — kalau ada error, paste mentahan ke AI
4. **Konfirmasi setiap langkah** — AI akan minta izin sebelum execute command
5. **Hasil release bisa dishare** — setelah sukses, Release ZIP bisa diupload
   ke GitHub Releases untuk dipakai user Realme C53 lain

---

## Lisensi Template

Bebas pakai. Feel free to modify sesuai kebutuhan.
