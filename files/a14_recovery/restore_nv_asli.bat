@echo off
REM ================================================================
REM  RESTORE NV ASLI + PRODNV ASLI (PEMULIHAN IMEI / BASEBAND)
REM
REM  MASALAH DITEMUKAN:
REM   - fix_imei_nv.bat dan fase 2 MENULIS NV TEMPLATE KOSONG
REM     (l_fixnv1_a = 2C7187DF, identik dengan template pabrik PAC)
REM     ke l_fixnv1_a, sehingga baseband = Unknown dan IMEI hilang.
REM   - prodnv di fase 2 ditulis dari PAC hanya 45KB (template),
REM     sementara prodnv asli perangkat = 64MB (ext4, berisi
REM     sprd_ss = secure storage berisi IMEI signed/terenkripsi).
REM
REM  SOLUSI: restore NV + prodnv ASLI perangkat dari
REM   D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh\
REM   (diambil 01-Aug-2026 sebagai titik revert segar).
REM
REM  SUMBER (hasil verifikasi SHA-1):
REM   - l_fixnv1_a.img = B40FEA4A88F6F55224B292A5FE6C353239CCCECD (NV asli)
REM   - l_fixnv2_a     = pakai file l_fixnv1_a.img (l_fixnv1==l_fixnv2 mirror)
REM   - prodnv.img     = 5856DF4C3047ABE378FFF7331288EA6BD136409E (64MB, asli)
REM
REM  Device harus dalam kondisi BROM (ulangi 3-kombinasi tombol:
REM  Volume UP + Volume DOWN + Power, tahan lalu colok USB).
REM ================================================================
setlocal
set BK=D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh
set TOOL=D:\realme-c53-recovery\01_alat\spd_tools
cd /d "%TOOL%"

spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-dl.bin 0x65000800 fdl fdl2-dl.bin 0x9EFFFE00 exec ^
  e l_fixnv1_a ^
  w l_fixnv1_a %BK%\l_fixnv1_a.img ^
  e l_fixnv2_a ^
  w l_fixnv2_a %BK%\l_fixnv1_a.img ^
  e prodnv ^
  w prodnv %BK%\prodnv.img

if errorlevel 1 (
  echo.
  echo GAGAL! Periksa log. Device mungkin perlu masuk BROM lagi.
  pause
) else (
  echo.
  echo ================================================================
  echo  RESTORE NV + PRODNV ASLI SELESAI.
  echo  Lepas USB, nyalakan HP normal (jangan ke BROM lagi).
  echo  Cek: Pengaturan - Tentang perangkat - Versi baseband,
  echo  lalu *#06# untuk IMEI.
  echo ================================================================
  pause
)
