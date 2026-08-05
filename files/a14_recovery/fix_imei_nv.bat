@echo off
REM ================================================================
REM  FIX IMEI: RESTORE NV ASLI DARI BACKUP A15
REM  Masalah: l_fixnv1_a (nvitem) gagal ditulis penuh saat fase 2,
REM  sehingga IMEI tidak terbaca di A14.
REM  Solusi: tulis ulang NV asli perangkat dari backup A15
REM  (D:\porting-custom-rom\backup\20260727_231930\).
REM  Device harus dalam kondisi BROM.
REM
REM  Urutan:
REM   - l_fixnv1_a <- l_fixnv1_a.img (nvitem, berisi IMEI)
REM   - l_fixnv2_a <- l_fixnv2_a.img (mirror l_fixnv1)
REM  (prodnv TIDAK diutamakan dulu - coba nvitem saja)
REM ================================================================
setlocal
set BK=D:\porting-custom-rom\backup\20260727_231930
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e l_fixnv1_a ^
  w l_fixnv1_a %BK%\l_fixnv1_a.img ^
  e l_fixnv2_a ^
  w l_fixnv2_a %BK%\l_fixnv2_a.img

if errorlevel 1 (
  echo.
  echo GAGAL! Periksa log. Device mungkin perlu masuk BROM lagi.
  pause
) else (
  echo.
  echo NV DITULIS. Lepas USB, nyalakan HP, cek *#06# lagi.
  echo Jika IMEI muncul: beres. Jika belum, kita coba restore prodnv juga.
  pause
)
