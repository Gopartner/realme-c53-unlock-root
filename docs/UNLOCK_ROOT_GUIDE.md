# Realme C53 (RMX3760) — Proses Unlock & Root (Terverifikasi)

> Status: **BERHASIL** — 02-Agu-2026
> Hasil terverifikasi pada **Android 14** dan **Android 15**.

## Ringkasan Hasil

| Item | Android 15 | Android 14 |
|------|-----------|-----------|
| **Unlock bootloader** (CVE-2022-38694) | ✅ OK | ✅ OK |
| **Root Magisk** | ✅ OK | ✅ OK |
| **KernelSU LKM (module-load)** | ✅ OK (`MODULE_SIG_FORCE=n`) | ❌ Diblokir (`MODULE_SIG_FORCE=y`) |

---

## 1. Identitas Device

### Varian Android 15 (firmware `RMX3760export_15_H.01` / `AP3A.240905.015.A2`)
- Kernel: `5.15.178-android13-8-g0c749b198e8d-ab44` (non-GKI)
- `CONFIG_MODULE_SIG_FORCE=n` → **KernelSU LKM bisa dimuat**
- kernelsu.ko matching vermagic: `5.15.178-android13-8-g0c749b198e8d-ab44`

### Varian Android 14 (firmware `RMX3760export_14_C.23`)
- Kernel: `5.4.254-android12-9-gf6794bd59091-ab267`
- Compiler: `clang 12.0.5` (Android 7284624), build `Mon Aug 5 17:45:18 CST 2024`
- `CONFIG_MODULES=y`, **`CONFIG_MODULE_SIG_FORCE=y`**, `CONFIG_MODVERSIONS=y`
- `insmod` modul tanpa tanda tangan vendor → **`Key was rejected by service`**
- Kesimpulan: **KernelSU LKM tidak dapat dimuat** pada varian A14 tanpa rebuild kernel + signing key sendiri.

> ⚠️ Periksa kernel device sebelum memilih metode root:
> `adb shell uname -r` → kalau `5.15.178` pakai KernelSU; kalau `5.4.254` pakai Magisk.

---

## 2. Prasyarat

- Windows + driver **SPRD** (`tools/driver/`) — device muncul sebagai `SPRD U2S Diag (COMx)`
- `spd_dump.exe` + `Channel9.dll` + `Channel.ini` (di `tools/unlock/sprd/`)
- FDL patched CVE: `fdl1-dl.bin` (MD5 `FC11D3E9003D4D858A3C846635AF9290`) & `fdl2-dl.bin` (MD5 `9494D6C2068E4A3A8B449592CE9BA45D`)
- Payload resmi: `spl-unlock.bin` (MD5 `7563FDD3BCA14D4364739FFA76C17E55`)
- ADB + Fastboot (Platform Tools)

> **Gagal di masa lalu:** memakai FDL stock (`fdl1-sign.bin`/`lk-fdl2-sign.bin`, signature-check ON)
> → `write uboot` ditolak `signature verification of "uboot_a" failed`.
> **Wajib** FDL patched CVE di atas.

---

## 3. Unlock Bootloader (CVE-2022-38694)

Urutan mengikuti `unlock_autopatch_9230.bat` resmi. Tiap langkah butuh **re-plug ke BROM** kecuali STEP 2→3.

**Mode BROM**: power off → tahan **Vol Up+Down** → colok USB → lepas tombol saat `SPRD U2S Diag` muncul.

```bat
REM BASE — handshake BROM + FDL patched
SET BASE=--wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec

REM STEP 1 — erase splloader (mode BROM)
spd_dump %BASE% e splloader reset            -> "Erase Part Done: splloader"

REM STEP 2 — tulis cboot patched (mode BROM, TIDAK perlu re-plug setelahnya)
spd_dump %BASE% w uboot fdl2-cboot.bin reset -> "Write Part Done: uboot_a"

REM tunggu ~8-10 detik device masuk cboot mode
REM STEP 3 — payload unlock (mode cboot, JANGAN cabut kabel, max 2-3x)
spd_dump --wait 30 exec_addr 0x65015f08 fdl spl-unlock.bin 0x65000800
REM   -> "EXEC FDL1" lalu device reboot (usb_send failed / device removed = normal)
REM   -> kemungkinan butuh 2x

REM STEP 4 — verifikasi miscdata (mode cboot)
spd_dump --wait 30 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec verbose 2 read_part miscdata 8192 64 m.bin reset
REM   -> m.bin nonzero (pola: 16-byte hash muncul 2x = "32 string + 16 hash + 16 hash") = UNLOCKED

REM STEP 5 — restore splloader + uboot + wipe misc
spd_dump --wait 30 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec r boot w splloader u-boot-spl-16k-sign.bin w uboot uboot_bak.bin w misc misc-wipe.bin reset
```

### File penting (jangan diganti)
| File | MD5 | Keterangan |
|------|-----|-----------|
| `fdl1-dl.bin` | `FC11D3E9003D4D858A3C846635AF9290` | FDL1 patched CVE (sig-check OFF) |
| `fdl2-dl.bin` | `9494D6C2068E4A3A8B449592CE9BA45D` | FDL2 patched CVE |
| `spl-unlock.bin` | `7563FDD3BCA14D4364739FFA76C17E55` | Payload CVE resmi |
| `u-boot-spl-16k-sign.bin` | — | SPL patched untuk restore |
| `uboot_bak.bin` | (proven boot) | Uboot stock untuk restore |

### Verifikasi unlock
```bash
adb shell getprop ro.boot.flash.locked        # 0
adb shell getprop ro.boot.vbmeta.device_state # unlocked
adb shell getprop ro.boot.verifiedbootstate   # orange
# Atau via Developer Options: status "OEM unlocking" = unlocked
```

---

## 4. Root Magisk

1. Patch boot stock (`output/backup/boot_a_a14_stock.img` / dump `boot_a` saat locked) dengan Magisk app v30.7 → `magisk_patched_boot_a14.img`.
2. Flash ke **kedua slot**:
   ```bash
   adb reboot bootloader
   fastboot flash boot_a magisk_patched_boot_a14.img
   fastboot flash boot_b magisk_patched_boot_a14.img
   fastboot reboot
   ```
3. Install `tools/apk/Magisk-v30.7.apk`, buka app (setup selesai, magiskd berjalan).
4. Grant root ke shell di app → **Superuser**, atau:
   ```bash
   adb shell su -c id   # uid=0(root) gid=0(root) context=u:r:magisk:s0
   ```

> Catatan: boot stock A14 **tidak punya ramdisk** — Magisk membuatkan ramdisk saat patch.
> `fastboot flash boot` (tanpa slot) gagal — selalu `boot_a` + `boot_b`.

---

## 5. KernelSU — Catatan Per Varian

### Android 15 (kernel 5.15.178) ✅
- `MODULE_SIG_FORCE=n` → ko unsigned bisa dimuat via `ksud late-load` / `insmod`.
- kernelsu.ko vermagic: `5.15.178-android13-8-g0c749b198e8d-ab44` (pakai `kernelsu_fixed.ko` yang versinya tanpa `+`).
- KSU-only via `ksud boot-patch` **rusak** (init binary gagal `init_module` — lihat `docs/KSU_INIT_BUG.md`).
- Solusi stabil: **hybrid Magisk + modul Magisk `ksu_loader`** (late-load kernelsu.ko).

### Android 14 (kernel 5.4.254) ❌ LKM
- `CONFIG_MODULE_SIG_FORCE=y` → modul harus ditandatangani dengan key build vendor (tidak ada di device).
- Tes: `insmod kernelsu.ko` → **`Key was rejected by service`**.
- Untuk memakai KernelSU di varian ini: rebuild seluruh kernel 5.4.254 (`kernel_source/`) dengan KSU terintegrasi + signing key sendiri, lalu flash boot.img baru.
- Praktis: gunakan **Magisk** (terverifikasi OK).

---

## 6. Log Sesi Berhasil (02-Agu-2026)

| Langkah | Hasil | Log |
|---------|-------|-----|
| STEP 1 erase splloader | `Erase Part Done: splloader` | `tools/unlock/sprd/log-01-erase.txt` |
| STEP 2 write cboot | `Write Part Done: uboot_a` (0x18a7d8) | `tools/unlock/sprd/log-02-cboot.txt` |
| STEP 3 payload (2x) | `EXEC FDL1` → device reboot | `log-03-payload.txt`, `log-03b-payload.txt` |
| STEP 4 verify miscdata | **62 byte nonzero** = UNLOCKED | `tools/unlock/sprd/log-04-verify.txt` |
| STEP 5 restore | splloader + uboot_a + misc OK | `tools/unlock/sprd/log-05-restore.txt` |
| Flash Magisk boot | boot_a + boot_b OKAY | — |
| Verifikasi root | `su -c id` = `uid=0(root)` | — |

### Poin penting dari sesi
- Device masuk BROM otomatis (tanpa tombol) karena splloader terhapus — ini normal selama proses.
- Log "noise UART lalu Close Channel" pada payload = device **tidak** di mode download (sudah boot Android). Pastikan device di BROM/cboot sebelum STEP 1-3.
- Payload STEP 3 sering perlu **2× percobaan** (komentar resmi: *"may need twice"*).

---

## 7. Recovery Bootloop

Jika device stuck (bootloop / black screen), pulihkan via BROM:
```bat
spd_dump --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9efffe00 exec r boot w splloader u-boot-spl-16k-sign.bin w uboot uboot_bak.bin w misc misc-wipe.bin reset
```
Atau pakai `tools/unlock/sprd/restore-boot.bat`.

---

## 8. Relock Bootloader (Terverifikasi 05-Agu-2026)

Hasil pada **Android 14 (RMX3760, kernel 5.4.254)**:
- `fastboot flashing lock` → **`Lock bootloader successfully!`**
- `ro.boot.flash.locked=1`, `verifiedbootstate=green`, `vbmeta.device_state=locked`
- HP boot normal ke Android (first boot setelah lock lebih lama karena factory reset)

### Urutan

```bash
# 1. Pastikan boot stock di KEDUA slot (hapus root Magisk dulu)
adb reboot bootloader
fastboot flash boot_a output/backup/boot_a_a14_stock.img
fastboot flash boot_b output/backup/boot_b_a14_stock.img

# 2. Kunci ulang (konfirmasi tombol volume di layar bila diminta)
fastboot flashing lock

# 3. Verifikasi
fastboot reboot
adb shell getprop ro.boot.flash.locked        # 1
adb shell getprop ro.boot.verifiedbootstate   # green
adb shell getprop ro.boot.vbmeta.device_state # locked
```

### Catatan
- Walaupun unlock dilakukan via CVE-2022-38694, perintah fastboot `flashing lock` tetap
  diimplementasikan oleh bootloader dan langsung menulis state lock ke `miscdata`.
- Sebelum lock, partisi yang disentuh exploit sudah direstore (splloader + uboot_a + misc),
  jadi tidak ada sisa modifikasi bootloader.
- Jika `fastboot flashing lock` gagal (`Not implement.`), fallback: nolkan marker `miscdata`
  offset `8192` (64 byte) via `spd_dump` — marker nol = state locked (kebalikan dari payload
  `spl-unlock.bin`).
